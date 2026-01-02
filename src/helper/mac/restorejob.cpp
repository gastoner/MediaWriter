/*
 * Fedora Media Writer
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
#include <QDebug>
#include <QFile>
#include <QProcess>
#include <QTextStream>
#include <QTimer>

RestoreJob::RestoreJob(const QString &where,
                       const QString &partitionTable,
                       const QString &filesystem,
                       const QString &label)
    : QObject(nullptr)
    , where(where)
    , m_partitionTable(partitionTable.isEmpty() ? "GPT" : partitionTable)
    , m_filesystem(filesystem.isEmpty() ? "ExFAT" : filesystem)
    , m_label(label.isEmpty() ? "FLASHDISK" : label)
{
    QTimer::singleShot(0, this, &RestoreJob::work);
}

void RestoreJob::work()
{
    QProcess diskUtil;
    diskUtil.setProgram("diskutil");
    diskUtil.setArguments(QStringList() << "unmountDisk" << where);
    diskUtil.start();
    diskUtil.waitForFinished();

    // Map partition table type to diskutil format
    // diskutil uses: GPT, MBR, APM (Apple Partition Map)
    QString partScheme = m_partitionTable.toUpper();
    if (partScheme == "DOS")
        partScheme = "MBR";
    else if (partScheme != "GPT" && partScheme != "MBR" && partScheme != "APM")
        partScheme = "GPT";  // Default to GPT

    // Map filesystem to diskutil format names
    // diskutil formats: ExFAT, FAT32 (or MS-DOS FAT32), JHFS+ (or HFS+), APFS, Free Space
    QString fsFormat = m_filesystem;
    QString fsLower = m_filesystem.toLower();
    if (fsLower == "fat32" || fsLower == "vfat")
        fsFormat = "FAT32";
    else if (fsLower == "exfat")
        fsFormat = "ExFAT";
    else if (fsLower == "hfs+" || fsLower == "hfs")
        fsFormat = "JHFS+";
    else if (fsLower == "apfs")
        fsFormat = "APFS";
    // Note: ext2/3/4, btrfs, xfs, ntfs are not natively supported by diskutil
    // For these, we would need additional tools or fall back to ExFAT
    else if (fsLower == "ext4" || fsLower == "ext3" || fsLower == "ext2" ||
             fsLower == "btrfs" || fsLower == "xfs" || fsLower == "ntfs") {
        QTextStream err(stderr);
        err << "Warning: " << m_filesystem << " is not supported by diskutil. Using ExFAT instead.\n";
        fsFormat = "ExFAT";
    }

    diskUtil.setProcessChannelMode(QProcess::ForwardedChannels);
    diskUtil.setArguments(QStringList() << "partitionDisk" << where << "1"
                                        << partScheme
                                        << fsFormat
                                        << m_label
                                        << "R");
    diskUtil.start();
    diskUtil.waitForFinished();

    qApp->exit(diskUtil.exitCode());
}
