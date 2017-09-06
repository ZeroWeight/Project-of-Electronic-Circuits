#include "userinterface.h"
#include <QtWidgets/QApplication>
#include <QDebug>
int main (int argc, char *argv[]) {
	QApplication a (argc, argv);
	QFile styleSheet ("UIstyle.qss");
	if (!styleSheet.open (QIODevice::ReadOnly)) {
		qWarning ("Can't open the style sheet file.");
	}
	else {
		qApp->setStyleSheet (styleSheet.readAll ());
		styleSheet.close ();
	}
	UserInterface w;
	w.show ();
	return a.exec ();
}