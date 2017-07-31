#include "userinterface.h"

UserInterface::UserInterface (QWidget *parent)
	: QMainWindow (parent) {
	ui.setupUi (this);
	int size = QApplication::desktop ()->height () / 500;
	this->setFixedHeight (460 * size);
	this->setFixedWidth (320 * size);
	this->setObjectName ("MainWindow");
	paint_area = new Painter (this);
	paint_area->size = size;
	paint_area->setGeometry (0, 0, 320 * size, 240 * size);
	for (int i = 0; i < 6; ++i) {
		Control_array[i] = new QPushButton (this);
		Control_array[i]->setGeometry (20 * size + (i % 3) * 100 * size, 270 * size + (i / 3) * 60 * size, 80 * size, 45 * size);
		Control_array[i]->setObjectName (QString ("button_") + QString::number (i));
	}
}

UserInterface::~UserInterface () {}