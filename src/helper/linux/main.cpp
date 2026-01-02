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

#include <QCoreApplication>
#include <QLocale>
#include <QTextStream>
#include <QTranslator>

#include "restorejob.h"
#include "writejob.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    QTranslator translator;
    if (translator.load(QLocale(QLocale::system().language(), QLocale::system().script(), QLocale::system().territory()), QLatin1String(), QLatin1String(), ":/translations")) {
        app.installTranslator(&translator);
    }

    if (app.arguments().count() >= 3 && app.arguments()[1] == "restore") {
        // restore <device> [partitionTable] [filesystem] [label]
        QString device = app.arguments()[2];
        QString partitionTable = app.arguments().count() > 3 ? app.arguments()[3] : "gpt";
        QString filesystem = app.arguments().count() > 4 ? app.arguments()[4] : "exfat";
        QString label = app.arguments().count() > 5 ? app.arguments()[5] : QString();
        new RestoreJob(device, partitionTable, filesystem, label);
    } else if (app.arguments().count() == 4 && app.arguments()[1] == "write") {
        new WriteJob(app.arguments()[2], app.arguments()[3]);
    } else {
        QTextStream err(stderr);
        err << "Helper: Wrong arguments entered\n";
        err << "Usage:\n";
        err << "  helper write <image> <device>\n";
        err << "  helper restore <device> [partitionTable] [filesystem] [label]\n";
        err << "    partitionTable: gpt (default) or dos\n";
        err << "    filesystem: exfat (default), ext4, ext3, ext2, btrfs, xfs, vfat, ntfs\n";
        err << "    label: optional volume label\n";
        return 1;
    }
    return app.exec();
}
