#ifndef USERINTERFACE_H
#define USERINTERFACE_H

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
	bool ready;
	void enqueue (const char& t) {
		QQueue::enqueue (unsigned char (t));
		if (this->size () >= (buffer_size << 1)) {
			emit read_out ();
		}
	}
};
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

	Ui::UserInterfaceClass ui;
	Button Control_array[6];
	QComboBox* settingCOM;
	QComboBox* settingBaudRate;
	QPushButton* uart_on_off;
	QTimer* timer;
};

#endif // USERINTERFACE_H
