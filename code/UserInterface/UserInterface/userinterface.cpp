#include "userinterface.h"

UserInterface::UserInterface (QWidget *parent)
	: QMainWindow (parent) {
	byte = 0xC0;//11 00 00 00
	ui.setupUi (this);
	size = QApplication::desktop ()->height () / 500;
	this->setFixedHeight (460 * size);
	this->setFixedWidth (320 * size);
	this->setObjectName ("MainWindow");
	core = new Bus (this, size);
	paint_area = new Painter (this);
	paint_area->setGeometry (0, 0, 320 * size, 240 * size);
	paint_area->show ();
	for (int i = 0; i < 12; ++i) {
		Control_array[i] = new QPushButton (this);
		Control_array[i]->setGeometry (20 * size + (i & 3) * 75 * size, 245 * size + (i >> 2) * 45 * size, 50 * size, 40 * size);
		Control_array[i]->setObjectName (QString ("button_") + QString::number (i));
		connect (Control_array[i], &QPushButton::pressed, [=] {
			switch (i) {
			case 0:byte = 0xD4; break;//11 01 01 00
			case 1:byte = 0xD0; break;//11 01 00 00
			case 2:byte = 0xD8; break;//11 01 10 00

			case 3:byte = 0xF0; break;//11 11 00 00

			case 4:byte = 0xC4; break;//11 00 01 00
			case 5:byte = 0xC0; break;//11 00 00 00
			case 6:byte = 0xC8; break;//11 00 10 00

			case 7:byte = 0xFC; break;//11 11 11 00

			case 8:byte = 0xE4; break;//11 10 01 00
			case 9:byte = 0xE0; break;//11 10 01 00
			case 10:byte = 0xE8; break;//11 10 01 00

			case 11:byte = 0xCC; break;//11 00 11 00
			default:break;
			}
		});
		connect (Control_array[i], &QPushButton::released, [=] {
			byte = 0xC0;
		});
	}
	//SerialPort Interface
	currentSerialPort = new SerialPort (this);
	sender = static_cast<QSerialPort*> (currentSerialPort);
	currentSerialPort->setReadBufferSize (0);
	settingCOM = new QComboBox (this);
	uart_on_off = new QPushButton (this);
	timer = new QTimer (this);
	timer->setInterval (10);

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
			timer->stop ();
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
				timer->start ();
			}
			else {
				QMessageBox::critical (this, tr ("Error"), tr ("Fail to turn on this device!"));
			}
		}
	});

	connect (currentSerialPort, &SerialPort::char_read, [=](QByteArray arr) {
		for (char ch : arr) {
			core->enqueue (ch);
		}
		currentSerialPort->pause = false;
	});

	connect (core, &Bus::all_update, [=](const QImage&img) {
		paint_area->img = img;
		paint_area->update ();
	});

	connect (timer, &QTimer::timeout, [=] {
		sender->putChar (byte);
	});

	this->setFocusPolicy (Qt::StrongFocus);
}

UserInterface::~UserInterface () {}

void UserInterface::keyPressEvent (QKeyEvent *event) {
	if (!event->isAutoRepeat ()) {
		switch (event->key ()) {
		case Qt::Key_B: byte |= 0x30; break;// 11 11 xx 00 -> break(F/B)
		case Qt::Key_R: byte |= 0x0C; break;// 11 xx 11 00 -> reset(R/L)
		case Qt::Key_Up: byte |= 0x10; byte &= 0xDF; break;// 11 01 xx 00 -> forward
		case Qt::Key_Down: byte |= 0x20; byte &= 0xEF; break;// 11 10 xx 00 backword
		case Qt::Key_Left: byte |= 0x04; byte &= 0xF7; break;// 11 xx 01 00 -> left trn
		case Qt::Key_Right: byte |= 0x08; byte &= 0xFB; break;//11 xx 10 00 -> right trn
		default:break;
		}
		qDebug () << 'P' << QString::number (byte, 2);
	}
}

void UserInterface::keyReleaseEvent (QKeyEvent*event) {
	if (!event->isAutoRepeat ()) {
		switch (event->key ()) {
		case Qt::Key_B:case Qt::Key_Up: case Qt::Key_Down: byte &= 0xCF; break;//11 00 xx 00 F/B stop
		case Qt::Key_R:case Qt::Key_Left:case Qt::Key_Right:byte &= 0xF3; break;//11 xx 00 R/L stop
		default: break;
		}
		qDebug () << 'R' << QString::number (byte, 2);
	}
}