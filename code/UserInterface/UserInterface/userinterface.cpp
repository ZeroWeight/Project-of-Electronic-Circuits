#include "userinterface.h"

UserInterface::UserInterface (QWidget *parent)
	: QMainWindow (parent) {
	byte = 0x00;//11 00 00 00
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
			case 0:byte = 0x6C; break;//011 011 00
			case 1:byte = 0x60; break;//011 000 00
			case 2:byte = 0x78; break;//011 110 00

			case 3:byte = 0xA0; break;//101 000 00

			case 4:byte = 0x0C; break;//000 011 00
			case 5:byte = 0x00; break;//000 000 00
			case 6:byte = 0x18; break;//000 110 00

			case 7:byte = 0xB4; break;//101 101 00

			case 8:byte = 0xCC; break;//110 011 00
			case 9:byte = 0xC0; break;//110 000 00
			case 10:byte = 0xD8; break;//110 110 00

			case 11:byte = 0x14; break;//000 101 00
			default:break;
			}
		});
		connect (Control_array[i], &QPushButton::released, [=] {
			byte = 0x00;
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
			//qDebug () << QString ("%1").arg (ch, 2, 16, QChar ('0'));
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

UserInterface::~UserInterface () {
	system ("del *.txt");
}

void UserInterface::keyPressEvent (QKeyEvent *event) {
	if (!event->isAutoRepeat ()) {
		switch (event->key ()) {
		case Qt::Key_B: byte &= 0x1F; byte |= 0xA0; break;// 101 yyy zz -> break(F/B)
		case Qt::Key_R: byte &= 0xE3; byte |= 0x14; break;// xxx 101 zz -> reset(R/L)
		case Qt::Key_Up: byte &= 0x1F; byte |= 0x60; break;// 011 yyy zz -> forward
		case Qt::Key_Down: byte &= 0x1F; byte |= 0xC0; break;// 110 yyy zz -> backword
		case Qt::Key_Left: byte &= 0xE3; byte |= 0x0C; break;// xxx 011 zz -> left trn
		case Qt::Key_Right: byte &= 0xE3; byte |= 0x18; break;//xxx 110 zz -> right trn
		default:break;
		}
		//qDebug () << 'P' << QString::number (byte, 2);
	}
}

void UserInterface::keyReleaseEvent (QKeyEvent*event) {
	if (!event->isAutoRepeat ()) {
		switch (event->key ()) {
		case Qt::Key_B:case Qt::Key_Up: case Qt::Key_Down: byte &= 0x1F; break;//000 yyy zz F/B stop
		case Qt::Key_R:case Qt::Key_Left:case Qt::Key_Right:byte &= 0xE3; break;//xxx 000 zz R/L stop
		default: break;
		}
		//qDebug () << 'R' << QString::number (byte, 2);
	}
}