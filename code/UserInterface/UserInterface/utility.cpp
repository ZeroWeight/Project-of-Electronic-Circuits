#include "userinterface.h"

#ifdef DEBUG
void Write2File::enqueue (const char& t) {
	list.last ()->enqueue (t);
	if (t == 0x0A && list.last ()->at (list.last ()->size () - 2) == 0x0D) {
		list.last ()->start ();
		Writer* ptr = new Writer (this, count++);
		connect (ptr, &Writer::Image, [=](const QImage& img) {
			emit all_update (img);
		});
		list.append (ptr);
	}
}
Write2File::Write2File (QObject * parent, int size) :QObject (parent) {
	_size = size;
	count = 0;
	list.clear ();
	Writer* ptr = new Writer (this, count++, _size);
	connect (ptr, &Writer::Image, [=](const QImage& img) {
		emit all_update (img);
	});
	list.append (ptr);
}
Write2File::~Write2File () {
	bool running = true;
	while (running) {
		running = false;
		for (Writer* w : list) {
			if (w->isRunning ()) running = true;
		}
	}
}

Writer::Writer (QObject* parent, int index, int size) : QThread (parent) {
	this->_size = size;
	file = new QFile (this);
	file->setFileName (QString::number (index) + ".pic");
	file->open (QIODevice::WriteOnly);
	stream = new QTextStream (file);
}

void Writer::run () {
	if (this->size () == buffer_size) {
		for (int i = 0; i < 240; ++i)for (int j = 0; j < 320; ++j) {
			unsigned ch1 = this->at (i * 320 + j);
			unsigned ch2 = this->at (i * 320 + j + 1);
			ans[i][j][0] = unsigned char (ch1 & 0xF8);
			ans[i][j][1] = unsigned char ((ch1 << 5) | (ch2 >> 3)) & 0xFC;
			ans[i][j][2] = unsigned char (ch2 << 3);
		}
		img = QImage ((const unsigned char*)(ans), 320, 240, QImage::Format_RGB888);
		emit Image (img);
	}
	for (unsigned char hex : *this) {
		(*stream) << QString ("%1").arg (hex, 2, 16, QChar ('0')) << ' ';
	}
	(*stream) << QString ("%1").arg (this->size (), 6, 10, QChar ('0')) << ' ';
	stream->flush ();
	file->close ();
}

Writer::~Writer () {
	delete stream;
	stream = nullptr;
}
#endif
SerialPort::SerialPort (QObject* parent) : QObject (parent) {
	running = false;
}

SerialPort::~SerialPort () {
	running = false;
	while (this->isRunning ());
}

void SerialPort::run () {
	while (running) {
		if (this->isReadable ()) {
			pause = true;
			emit this->char_read (this->read (1));
			while (pause);
		}
	}
}

void SerialPort::close () {
	running = false;
	while (this->isRunning ());
	QSerialPort::close ();
}

bool SerialPort::open (OpenMode mode) {
	if (QSerialPort::open (mode)) {
		this->start ();
		running = true;
		return true;
	}
	else return false;
}

void Painter::paintEvent (QPaintEvent *) {
	qDebug () << "Update";
	QPainter p (this);
	p.drawImage (this->rect (), this->img);
}