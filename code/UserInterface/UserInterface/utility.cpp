#include "userinterface.h"
#ifdef DEBUG
void Write2File::enqueue (const char& t) {
	list.last ()->enqueue (t);
	if (t == 0x0A && list.last ()->at (list.last ()->size () - 2) == 0x0D) {
		list.last ()->start ();
		Writer* ptr = new Writer (this, count++);
		list.append (ptr);
	}
}
Write2File::Write2File (QObject * parent) :QObject (parent) {
	count = 0;
	list.clear ();
	Writer* ptr = new Writer (this, count++);
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
Writer::Writer (QObject* parent, int index) : QThread (parent) {
	file = new QFile (this);
	file->setFileName (QString::number (index) + ".pic");
	file->open (QIODevice::WriteOnly);
	stream = new QTextStream (file);
}
void Writer::run () {
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

void Buffer::enqueue (const char& t) {
	if (list.last ()->size () == buffer_size - 1 && t == 0x0A && list.last ()->at (list.last ()->size () - 2) == 0x0D) {
		list.last ()->enqueue (t);
		QQueue<unsigned char>*ptr = new QQueue<unsigned char> ();
		list.append (ptr);
		index++;
		if (!this->isRunning ()) {
			fin = index - 1;
			this->start ();
		}
	}
	else if (list.last ()->size () >= 2 && t == 0x0A && list.last ()->at (list.last ()->size () - 2) == 0x0D) {
		list.last ()->clear ();
	}
	else list.last ()->enqueue (t);
}

void Buffer::run () {
	unsigned char ch1, ch2;
	for (int i = 0; i < 240; ++i)for (int j = 0; j < 320; ++j) {
		ch1 = list.at (fin)->dequeue ();
		ch2 = list.at (fin)->dequeue ();
		ans[240 - i][j][0] = unsigned char (ch1 & 0xF8);
		ans[240 - i][j][1] = unsigned char ((ch1 << 5) | (ch2 >> 3)) & 0xFC;
		ans[240 - i][j][2] = unsigned char (ch2 << 3);
	}
	//cv::Mat mat_ori = cv::Mat (240, 320, CV_8UC3, ans);
	//cv::Mat mat_des = cv::Mat (240 * _size, 320 * _size, CV_8UC3);
	//cv::Mat rgb;
	//cvtColor (mat_des, rgb, CV_BGR2RGB);
	img = QImage ((const unsigned char*)(ans),  //(const unsigned char*)
		320, 240,
		240 * 3,
		QImage::Format_RGB888);
	emit ImageUpdate (img);
}
Buffer::Buffer (QObject * parent) :QObject (parent) {
	fin = index = 0;
	QQueue<unsigned char>* ptr = new QQueue<unsigned char> ();
	list.append (ptr);
}

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
			QByteArray* ptr = new QByteArray (this->read (1));
			pause = true;
			emit this->char_read (ptr);
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