#include "userinterface.h"

UserInterface::UserInterface (QWidget *parent)
	: QMainWindow (parent) {
	ui.setupUi (this);
	size = QApplication::desktop ()->height () / 500;
	this->setFixedHeight (460 * size);
	this->setFixedWidth (320 * size);
	this->setObjectName ("MainWindow");
	buffer = new Buffer (this);
#ifdef DEBUG
	W2F = new Write2File (this);
#endif
	paint_area = new QLabel ("interesting", this);
	buffer->_size = size;
	paint_area->setGeometry (0, 0, 320 * size, 240 * size);
	for (int i = 0; i < 6; ++i) {
		Control_array[i] = new QPushButton (this);
		Control_array[i]->setGeometry (20 * size + (i % 3) * 100 * size, 270 * size + (i / 3) * 60 * size, 80 * size, 45 * size);
		Control_array[i]->setObjectName (QString ("button_") + QString::number (i));
	}
	//SerialPort Interface
	currentSerialPort = new SerialPort (this);
	currentSerialPort->setReadBufferSize (0);
	settingCOM = new QComboBox (this);
	uart_on_off = new QPushButton (this);

	settingCOM->setObjectName ("settingCOM");
	settingCOM->setGeometry (20 * size, 390 * size, 280 * size, 20 * size);
	uart_on_off->setObjectName ("on_off");
	uart_on_off->setGeometry (20 * size, 430 * size, 280 * size, 20 * size);
	uart_on_off->setText (tr ("Turn On"));

	settingCOM->clear ();
	foreach (auto const &info, QSerialPortInfo::availablePorts ())
		settingCOM->addItem (info.portName () + ": " + info.description ());
	settingCOM->setCurrentIndex (0);
	settingCOM->setToolTip (settingCOM->currentText ());

	currentUartState = UartState::OFF;
	connect (currentSerialPort, static_cast<void(QSerialPort::*)(QSerialPort::SerialPortError)>(&QSerialPort::error),
		[=](QSerialPort::SerialPortError error) {
		if (error == QSerialPort::ResourceError) {
			QMessageBox::critical (this, tr ("Error"), tr ("The device is unexpectedly removed!"));
			settingCOM->removeItem (settingCOM->currentIndex ());
			if (currentUartState == UartState::ON)
				uart_on_off->click ();
		}
	});

	connect (settingCOM, &QComboBox::currentTextChanged, [=] {
		settingCOM->setToolTip (settingCOM->currentText ());
	});

	connect (settingCOM, static_cast<void (QComboBox:: *)(const QString &)>(&QComboBox::highlighted)
		, [](const QString &text) {
		QToolTip::showText (QCursor::pos (), text);
	});

	connect (uart_on_off, &QPushButton::clicked, [=] {
		if (currentUartState == UartState::ON) {
			currentSerialPort->close ();
			currentUartState = UartState::OFF;
			uart_on_off->setText (tr ("Turn On"));
		}
		else {
			currentSerialPort->setPortName (settingCOM->currentText ().split (':').at (0));
			currentSerialPort->setBaudRate (BaudRate);
			currentSerialPort->setFlowControl (QSerialPort::NoFlowControl);
			currentSerialPort->setDataBits (static_cast<QSerialPort::DataBits>(8));
			currentSerialPort->setStopBits (QSerialPort::OneStop);
			currentSerialPort->setParity (QSerialPort::NoParity);
			if (currentSerialPort->open (QSerialPort::ReadWrite)) {
				currentUartState = UartState::ON;
				uart_on_off->setText (tr ("Turn Off"));
			}
			else {
				QMessageBox::critical (this, tr ("Error"), tr ("Fail to turn on this device!"));
			}
		}
	});

	connect (currentSerialPort, &SerialPort::char_read, [=](QByteArray* arr) {
		for (char ch : (*arr)) {
			buffer->enqueue (ch);
#ifdef DEBUG
			W2F->enqueue (ch);
#endif
		}
		delete arr;
		currentSerialPort->pause = false;
	});

	connect (buffer, &Buffer::ImageUpdate, [=](const QImage& img) {
		paint_area->setPixmap (QPixmap::fromImage (img));
	});
}

UserInterface::~UserInterface () {}