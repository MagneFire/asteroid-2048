TARGET = asteroid-2048
CONFIG += asteroidapp

SOURCES += main.cpp
RESOURCES +=   resources.qrc
OTHER_FILES +=

lupdate_only{ SOURCES += i18n/asteroid-2048.desktop.h }
TRANSLATIONS = $$files(i18n/$$TARGET.*.ts)
