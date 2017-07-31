#include "userinterface.h"

UserInterface::UserInterface (QWidget *parent)
	: QMainWindow (parent) {
	ui.setupUi (this);
	paint_area = new Painter (this);
	paint_area->setGeometry (0, 0, 640, 480);
}

UserInterface::~UserInterface () {}