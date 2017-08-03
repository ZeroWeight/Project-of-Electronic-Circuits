#include "userinterface.h"

UserInterface::UserInterface (QWidget *parent)
	: QMainWindow (parent) {
	ui.setupUi (this);
	int size = QApplication::desktop ()->height () / 500;
	this->setFixedHeight (460 * size);
	this->setFixedWidth (320 * size);
	this->setObjectName ("MainWindow");
	buffer = new Buffer (this);
#ifdef DEBUG
	W2F = new Write2File (this);
#endif
	paint_area = new Painter (this);
	paint_area->size = size;

#pragma region debug_image
#ifdef DEBUG
	for (int i = 0; i < 240; ++i) {
		for (int j = 0; j < 320; ++j)
			if (i < 50 && j < 50) {
				paint_area->ans[i][j][0] = 255;
				paint_area->ans[i][j][1] = 0;
				paint_area->ans[i][j][2] = 0;
			}
			else if (i > 190 && j > 270) {
				paint_area->ans[i][j][0] = 0;
				paint_area->ans[i][j][1] = 255;
				paint_area->ans[i][j][2] = 0;
			}
			else if (i < 50 && j>270) {
				paint_area->ans[i][j][0] = 0;
				paint_area->ans[i][j][1] = 0;
				paint_area->ans[i][j][2] = 255;
			}
			else if (i > 190 && j < 50) {
				paint_area->ans[i][j][0] = 255;
				paint_area->ans[i][j][1] = 255;
				paint_area->ans[i][j][2] = 0;
			}
			else if (double (i) / 240 < double (j) / 320) {
				paint_area->ans[i][j][0] = 255;
				paint_area->ans[i][j][1] = 0;
				paint_area->ans[i][j][2] = 255;
			}
			else {
				paint_area->ans[i][j][0] = 0;
				paint_area->ans[i][j][1] = 255;
				paint_area->ans[i][j][2] = 255;
			}
	}
#endif
#pragma endregion

	paint_area->setGeometry (0, 0, 320 * size, 240 * size);
	for (int i = 0; i < 6; ++i) {
		Control_array[i] = new QPushButton (this);
		Control_array[i]->setGeometry (20 * size + (i % 3) * 100 * size, 270 * size + (i / 3) * 60 * size, 80 * size, 45 * size);
		Control_array[i]->setObjectName (QString ("button_") + QString::number (i));
	}
	//SerialPort Interface
	currentSerialPort = new QSerialPort (this);
	currentSerialPort->setReadBufferSize (0);
	settingCOM = new QComboBox (this);
	settingBaudRate = new QComboBox (this);
	uart_on_off = new QPushButton (this);

	settingCOM->setObjectName ("settingCOM");
	settingCOM->setGeometry (20 * size, 390 * size, 200 * size, 20 * size);
	settingBaudRate->setObjectName ("settingBaudRate");
	settingBaudRate->setGeometry (240 * size, 390 * size, 60 * size, 20 * size);
	uart_on_off->setObjectName ("on_off");
	uart_on_off->setGeometry (20 * size, 430 * size, 280 * size, 20 * size);
	uart_on_off->setText (tr ("Turn On"));

	settingCOM->clear ();
	foreach (auto const &info, QSerialPortInfo::availablePorts ())
		settingCOM->addItem (info.portName () + ": " + info.description ());
	settingCOM->setCurrentIndex (0);
	settingCOM->setToolTip (settingCOM->currentText ());
	settingBaudRate->clear ();
	foreach (auto const &baudRate, QSerialPortInfo::standardBaudRates ())
		settingBaudRate->addItem (QString::number (baudRate));
	settingBaudRate->setCurrentText ("115200");
	timer = new QTimer (this);
	timer->setInterval (0);

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
			timer->stop ();
			uart_on_off->setText (tr ("Turn On"));
		}
		else {
			currentSerialPort->setPortName (settingCOM->currentText ().split (':').at (0));
			currentSerialPort->setBaudRate (settingBaudRate->currentText ().toInt ());
			currentSerialPort->setFlowControl (QSerialPort::NoFlowControl);
			currentSerialPort->setDataBits (static_cast<QSerialPort::DataBits>(8));
			currentSerialPort->setStopBits (QSerialPort::OneStop);
			currentSerialPort->setParity (QSerialPort::NoParity);

			if (currentSerialPort->open (QSerialPort::ReadWrite)) {
				currentUartState = UartState::ON;
				timer->start ();
				buffer->clear ();
				uart_on_off->setText (tr ("Turn Off"));
			}
			else {
				QMessageBox::critical (this, tr ("Error"), tr ("Fail to turn on this device!"));
			}
		}
	});

	connect (timer, &QTimer::timeout, [=] {
		if (currentSerialPort->isReadable ()) {
			QByteArray data = currentSerialPort->readAll ();
			if (data.isEmpty ()) return;
			else {
				for (char ch : data) {
					buffer->enqueue (ch);
					W2F->enqueue (ch);
				}
			}
		}
	});

	connect (buffer, &Buffer::read_out, [=] {
		unsigned char ch1, ch2, R, G, B;
		if (buffer->at (buffer_size - 1) - unsigned char (0x0A) || buffer->at (buffer_size - 2) - unsigned char (0x0D)) {
			while (buffer->size () >= buffer_size) {
				if (buffer->dequeue () == 0x0A) {
					if (!buffer->isEmpty () &&
						buffer->at (buffer_size - 1) == unsigned char (0x0A) &&
						buffer->at (buffer_size - 2) == unsigned char (0x0D))
						break;
				}
			}
			if (buffer->size () < buffer_size) return;
		}
		for (int i = 0; i < 240; ++i)for (int j = 0; j < 320; ++j) {
			ch1 = buffer->dequeue ();
			ch2 = buffer->dequeue ();
			R = (ch1 & 0xF8);
			G = ((ch1 << 5) | (ch2 >> 3)) & 0xFC;
			B = (ch2 << 3);
			paint_area->ans[240 - i][j][0] = GLubyte (R);
			paint_area->ans[240 - i][j][1] = GLubyte (G);
			paint_area->ans[240 - i][j][2] = GLubyte (B);
		}
		buffer->dequeue ();
		buffer->dequeue ();
		paint_area->updateGL ();
	});
	//QMetaObject::invokeMethod (paint_area, "updateGL", Qt::QueuedConnection);
}

UserInterface::~UserInterface () {}