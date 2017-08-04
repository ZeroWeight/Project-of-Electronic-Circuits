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
#include <QLabel>
#include <QSerialPortInfo>
#include <QMessageBox>
#include <QFile>
#include <QTextStream>
#include <QList>
#include <QThread>
#include <QImage>
#include <QQueue>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/imgproc.hpp>
const int buffer_size = 153602;//a image is followed with 0x0D,0x0A
const int BaudRate = 1382400;
typedef QQueue<unsigned char> * Q;
class Buffer :public QObject, public QThread {
	Q_OBJECT
		signals :
	void ImageUpdate (const QImage&);
private:
	QImage img;
	QList<Q> list;
	int index;
	int fin;
	unsigned char ans[240][320][3] = { 0 };
protected:
	void run ()override;
public:
	int _size;
	void enqueue (const char& t);
	Buffer (QObject * parent = nullptr);
};
#ifdef DEBUG
class Writer :public QQueue<unsigned char>, public QThread {
private:
	QFile* file;
	QTextStream* stream;
protected:
	void run ()override;
public:
	Writer (QObject * parent = nullptr, int index = 0);
	~Writer ();
};
class Write2File :public QObject {
private:
	QList <Writer*> list;
	int count;
public:
	Write2File (QObject * parent = nullptr);
	~Write2File ();
	void enqueue (const char& t);
};

#endif

class SerialPort :public QThread, public QSerialPort, public QObject {
	Q_OBJECT
protected:
	void run ()override;
public:
	bool running;
	bool pause;
	SerialPort (QObject * parent = nullptr);
	~SerialPort ();
	void close ()override;
	bool open (OpenMode mode)override;
signals:
	void char_read (QByteArray*);
};
typedef QPushButton* Button;
class UserInterface : public QMainWindow {
	Q_OBJECT

public:
	UserInterface (QWidget *parent = 0);
	~UserInterface ();
private:
	int size;
	enum class UartState { ON, OFF } currentUartState;
	QLabel* paint_area;
	SerialPort *currentSerialPort;
	Buffer* buffer;
#ifdef DEBUG
	Write2File* W2F;
#endif
	Ui::UserInterfaceClass ui;
	Button Control_array[6];
	QComboBox* settingCOM;
	QPushButton* uart_on_off;
signals:
	void ReadyRead ();
};

#endif // USERINTERFACE_H
