#ifndef USERINTERFACE_H
#define USERINTERFACE_H
#include "ui_userinterface.h"

#include <QApplication>
#include <QComboBox>
#include <QDebug>
#include <QDesktopWidget>
#include <QFile>
#include <QImage>
#include <QList>
#include <QMainWindow>
#include <QMessageBox>
#include <QObject>
#include <QPainter>
#include <QPushButton>
#include <QQueue>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QToolTip>
#include <QTextStream>
#include <QThread>
#include <QWidget>

const int buffer_size = 153602;//a image is followed with 0x0D,0x0A
const int BaudRate = 1382400;
typedef QQueue<unsigned char> * Q;
typedef QPushButton* Button;

class Painter :public QWidget {
	Q_OBJECT
public:
	QImage img;
	Painter (QWidget * parent = nullptr) :QWidget (parent) {};
	public slots:
	void paintEvent (QPaintEvent *event)override;
};
class Writer :public QThread, public QQueue<unsigned char> {
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
class Bus :public QObject {
	Q_OBJECT
		signals :
	void all_update (const QImage&);
private:
	QList <Writer*> list;
	int count;
	int _size;
public:
	Bus (QObject * parent = nullptr, int size = 1);
	~Bus ();
	void enqueue (const char& t);
};
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
	Bus* W2F;
	Ui::UserInterfaceClass ui;
	Button Control_array[6];
	QComboBox* settingCOM;
	QPushButton* uart_on_off;
signals:
	void ReadyRead ();
};

#endif // USERINTERFACE_H
