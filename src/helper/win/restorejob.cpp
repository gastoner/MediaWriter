/*
 * Fedora Media Writer
 * Copyright (C) 2024 Jan Grulich <jgrulich@redhat.com>
 * Copyright (C) 2016 Martin Bříza <mbriza@redhat.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include "restorejob.h"

#include <QCoreApplication>
#include <QTextStream>
#include <QThread>
#include <QTimer>

RestoreJob::RestoreJob(const QString &driveNumber,
                       const QString &partitionTable,
                       const QString &filesystem,
                       const QString &label,
                       QObject *parent)
    : QObject(parent)
    , m_partitionTable(partitionTable.isEmpty() ? "gpt" : partitionTable.toLower())
    , m_filesystem(filesystem.isEmpty() ? "exfat" : filesystem.toLower())
    , m_label(label)
{
    auto index = driveNumber.toInt();
    m_diskManagement = std::make_unique<WinDiskManagement>(this, true);
    m_disk = m_diskManagement->getDiskDriveInformation(index);

    QTimer::singleShot(0, this, &RestoreJob::work);
}

void RestoreJob::work()
{
    HANDLE drive;
    const QString drivePath = QString("\\\\.\\PhysicalDrive%0").arg(m_disk->index());

    /*
     * Formatting has to be apparently done in this order to be successful
     */

    /*
     * 0) Refresh information about partitions
     *    Uses WMI query
     */
    m_diskManagement->refreshDiskDrive(m_disk->path());

    /*
     * 1) Unmount all currently mounted volumes
     *    Uses DeleteVolumeMountPointA call from WinAPI
     *    We probably don't need to fail on this step and can try to continue
     */
    if (!m_diskManagement->removeDriveLetters(m_disk->index())) {
        m_diskManagement->logMessage(QtCriticalMsg, "Couldn't remove drive mountpoints");
        m_err << tr("Couldn't remove drive mountpoints") << "\n";
        m_err.flush();
        return;
    }

    /*
     * 2) Remove all the existing partitions
     *    This uses "DeleteObject" on MSFT_Partition using QMI query
     */
    if (!m_diskManagement->clearPartitions(m_disk->index())) {
        m_diskManagement->logMessage(QtCriticalMsg, "Failed to remove partitions from the drive");
        m_err << tr("Failed to remove partitions from the drive") << "\n";
        m_err.flush();
        qApp->exit(1);
        return;
    }

    drive = CreateFile(drivePath.toStdWString().c_str(), GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (drive == INVALID_HANDLE_VALUE) {
        m_diskManagement->logMessage(QtCriticalMsg, "Failed to open the drive for formatting");
        m_err << tr("Failed to open the drive for formatting") << "\n";
        m_err.flush();
        qApp->exit(1);
    }
    auto cleanup = qScopeGuard([=] {
        m_diskManagement->unlockDrive(drive);
        CloseHandle(drive);
    });

    /*
     * 3) Lock the drive for the rest of the process
     *    Uses DeviceIoControl(FSCTL_LOCK_VOLUME) from WinAPI
     */
    if (!m_diskManagement->lockDrive(drive, 10)) {
        m_diskManagement->logMessage(QtCriticalMsg, "Couldn't lock the drive");
        m_err << tr("Couldn't lock the drive") << "\n";
        m_err.flush();
        qApp->exit(1);
    }

    /*
     * 4) Refresh information about partition layout
     *    Uses DeviceIoControl(IOCTL_DISK_UPDATE_PROPERTIES) from WinAPI
     */
    m_diskManagement->refreshPartitionLayout(drive);

    /*
     * 5) Removes GPT/MBR records at the beginning and the end of the drive
     *    Writes zeroes to the beginning and the end of the drive
     */
    if (!m_diskManagement->clearPartitionTable(drive, m_disk->size(), m_disk->sectorSize())) {
        m_diskManagement->logMessage(QtCriticalMsg, "Failed to clear the partition table on the drive");
        m_err << tr("Failed to clear the partition table on the drive") << "\n";
        m_err.flush();
        qApp->exit(1);
    }

    /*
     * 6) Sets the drive to the RAW state
     *    Uses DeviceIoControl(IOCTL_DISK_CREATE_DISK) with PARTITION_STYLE_RAW
     */
    if (!m_diskManagement->clearDiskDrive(drive)) {
        m_diskManagement->logMessage(QtCriticalMsg, "Failed to set the drive to RAW partition style");
        m_err << tr("Failed to set the drive to RAW partition style") << "\n";
        m_err.flush();
        qApp->exit(1);
    }

    /*
     * 7) Create a new partition on the drive with the specified partition table type
     *    Uses DeviceIoControl(IOCTL_DISK_CREATE_DISK) with DeviceIoControl(IOCTL_DISK_SET_DRIVE_LAYOUT_EX) from WinAPI
     */
    bool partitionCreated = false;
    if (m_partitionTable == "dos" || m_partitionTable == "mbr") {
        // Create MBR partition
        partitionCreated = m_diskManagement->createMBRPartition(drive, m_disk->size(), m_disk->sectorSize());
        if (!partitionCreated) {
            m_diskManagement->logMessage(QtCriticalMsg, "Failed to create an MBR partition on the drive");
            m_err << tr("Failed to create an MBR partition on the drive") << "\n";
            m_err.flush();
            qApp->exit(1);
        }
    } else {
        // Default to GPT partition
        partitionCreated = m_diskManagement->createGPTPartition(drive, m_disk->size(), m_disk->sectorSize());
        if (!partitionCreated) {
            m_diskManagement->logMessage(QtCriticalMsg, "Failed to create a GPT partition on the drive");
            m_err << tr("Failed to create a GPT partition on the drive") << "\n";
            m_err.flush();
            qApp->exit(1);
        }
    }

    // FIXME: isn't this too much? We used to have this even before as
    // apparently it was suggested after diskpart operations
    QThread::sleep(15);

    /*
     * 8) Get GUID name of the partition
     *    Uses WinAPI to go through volumes and to get the GUID name
     */
    QString logicalName = m_diskManagement->getLogicalName(m_disk->index());
    if (logicalName.isEmpty()) {
        m_diskManagement->logMessage(QtCriticalMsg, "Failed to get GUID volume path on the drive");
        m_err << tr("Failed to get GUID volume path on the drive") << "\n";
        m_err.flush();
        qApp->exit(1);
    }

    m_diskManagement->refreshDiskDrive(m_disk->path());

    /*
     * 9) Attempt to mount a volume using the GUID path we get above
     *    Uses GetVolumePathNamesForVolumeNameA() to check whether the volume is already mounted, or
     *    SetVolumeMountPointA() to mount the partition. Returns assigned drive letter.
     */
    QChar driveLetter = m_diskManagement->mountVolume(logicalName);
    if (!driveLetter.isLetter()) {
        m_diskManagement->logMessage(QtCriticalMsg, "Failed to remove partitions from the drive");
        m_err << tr("Failed to mount the new partition") << "\n";
        m_err.flush();
        qApp->exit(1);
    }

    /*
     * 10) Format the partition with the specified filesystem
     *     Uses "Format" method on the MSFT_Volume object using WMI query.
     */
    if (!m_diskManagement->formatPartition(driveLetter, m_filesystem, m_label)) {
        m_diskManagement->logMessage(QtCriticalMsg, QString("Failed to format the partition to %1").arg(m_filesystem).toStdString().c_str());
        m_err << tr("Failed to format the partition to %1").arg(m_filesystem) << "\n";
        m_err.flush();
        qApp->exit(1);
    }

    qApp->exit(0);
}
