#ifndef USERINTERFACE_H
#define USERINTERFACE_H
#define DEBUG
#include "ui_userinterface.h"
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QPushButton>
#include <QGLWidget>
#include <QDesktopWidget>
#include <QFile>
#include <QObject>
#include <QToolTip>
#include <QApplication>
#include <QPushButton>
#include <QComboBox>
#include <QGL>
#include <QSerialPort>
#include <QTimer>
#include <QSerialPortInfo>
#include <QMessageBox>
#include <QFile>
#include <QTextStream>
#include <QThread>
#include <QQueue>
#include <GL/GLU.h>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/imgproc.hpp>
const int buffer_size = 153602;//a image is followed with 0x0D,0x0A
class Painter :public QGLWidget {
	Q_OBJECT
public:
	int size;
	GLubyte ans[240][320][3] = { 0 };
	Painter (QWidget* parent = 0);
	~Painter ();
private:
	void resizeGL (int w, int h)override;
	void initializeGL ()override;
	void paintGL () override;
};
class Buffer :public QObject, public QQueue<unsigned char> {
	Q_OBJECT
		signals :
	void read_out ();
public:
	void enqueue (const char& t) {
		QQueue::enqueue (unsigned char (t));
		if (this->size () >= (buffer_size << 1)) {
			emit read_out ();
		}
	}
};
#ifdef DEBUG
class Write2File :public QObject, public QQueue<unsigned char>, public QThread {
	Q_OBJECT
private:
	QFile* file;
	QTextStream* stream;
	QQueue<unsigned char> temp;
	int count;
	int s;
protected:
	void run ()override {
		file->setFileName (QString::number (count++) + ".pic");
		file->open (QIODevice::WriteOnly);
		for (unsigned char hex : temp) {
			(*stream) << QString ("%1").arg (hex, 2, 16, QChar ('0')) << ' ';
		}
		(*stream) << QString ("%1").arg (temp.size (), 10, 10, QChar ('0')) << ' ';
		stream->flush ();
		temp.clear ();
		file->close ();
	}
public:
	Write2File () {
		count = 0;
		file = new QFile ();
		stream = new QTextStream (file);
	}
	//~Write2File () {
	//	stream->flush ();
	//	DeleteObject (stream);
	//	stream = nullptr;
	//	file->deleteLater ();
	//	file = nullptr;
	//}
	void enqueue (const char& t) {
		QQueue::enqueue (unsigned char (t));
		if (unsigned char (t) == 0x0A && this->at (this->size () - 2) == 0x0D) {
			s = this->size ();
			for (int i = 0; i < s; ++i)
				temp.enqueue (this->dequeue ());
			this->start ();
		}
	}
};
#endif
typedef QPushButton* Button;
class UserInterface : public QMainWindow {
	Q_OBJECT

public:
	UserInterface (QWidget *parent = 0);
	~UserInterface ();
private:
	enum class UartState { ON, OFF } currentUartState;
	Painter* paint_area;
	QSerialPort *currentSerialPort;
	Buffer* buffer;
#ifdef DEBUG
	Write2File* W2F;
#endif
	Ui::UserInterfaceClass ui;
	Button Control_array[6];
	QComboBox* settingCOM;
	QComboBox* settingBaudRate;
	QPushButton* uart_on_off;
	QTimer* timer;
};

#endif // USERINTERFACE_H
