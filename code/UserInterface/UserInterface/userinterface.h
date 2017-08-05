#ifndef USERINTERFACE_H
#define USERINTERFACE_H
#define DEBUG
#include "ui_userinterface.h"
#include <QPushButton>
#include <QDesktopWidget>
#include <QFile>
#include <QObject>
#include <QMainWindow>
#include <QToolTip>
#include <QApplication>
#include <QPushButton>
#include <QComboBox>
#include <QSerialPort>
#include <QTimer>
#include <QLabel>
#include <QSerialPortInfo>
#include <QMessageBox>
#include <QTextStream>
#include <QPainter>
#include <QList>
#include <QThread>
#include <QImage>
#include <qdebug.h>
#include <QWidget>
#include <QQueue>
const int buffer_size = 153602;//a image is followed with 0x0D,0x0A
const int BaudRate = 1382400;
typedef QQueue<unsigned char> * Q;
class Painter :public QWidget {
	Q_OBJECT
public:
	QImage img;
	Painter (QWidget * parent = nullptr) :QWidget (parent) {};
	public slots:
	void paintEvent (QPaintEvent *event)override;
};
#ifdef DEBUG
class Writer :public QObject, public QQueue<unsigned char>, public QThread {
	Q_OBJECT
		signals :
	void Image (const QImage&);
private:
	QImage img;
	int _size;
	unsigned char ans[240][320][3] = { 0 };
	QFile* file;
	QTextStream* stream;
protected:
	void run ()override;
public:
	Writer (QObject * parent = nullptr, int index = 0, int size = 1);
	~Writer ();
};
class Write2File :public QObject {
	Q_OBJECT
		signals :
	void all_update (const QImage&);
private:
	QList <Writer*> list;
	int count;
	int _size;
public:
	Write2File (QObject * parent = nullptr, int size = 1);
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
	void char_read (QByteArray);
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
	Painter* paint_area;
	SerialPort *currentSerialPort;
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
