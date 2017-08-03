#include "userinterface.h"
#ifdef DEBUG
void Write2File::enqueue (const char& t) {
	QQueue::enqueue (unsigned char (t));
	if (unsigned char (t) == 0x0A && this->at (this->size () - 2) == 0x0D) {
		Writer* ptr = new Writer (this, count++);
		while (!this->isEmpty ()) {
			ptr->enqueue (this->dequeue ());
		}
		list.append (ptr);
		ptr->start ();
	}
}
Write2File::Write2File (QObject * parent) :QObject (parent) {
	count = 0;
	list.clear ();
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
	QQueue::enqueue (unsigned char (t));
	if (this->size () >= (buffer_size << 1)) {
		emit read_out ();
	}
}

Buffer::Buffer (QObject * parent) :QObject (parent) {}