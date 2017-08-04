#include <QtCore/QCoreApplication>
#include <QSerialPort>
#include <QString>
#include <QObject>
#include <QTimer>
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
int main (int argc, char *argv[]) {
	QCoreApplication a (argc, argv);
	QSerialPort sp;
	QTimer timer;
	timer.setInterval (5);
	sp.setPortName ("COM2");
	sp.setBaudRate (1152000);
	sp.setFlowControl (QSerialPort::NoFlowControl);
	sp.setDataBits (static_cast<QSerialPort::DataBits>(8));
	sp.setStopBits (QSerialPort::OneStop);
	sp.setParity (QSerialPort::NoParity);
	sp.open (QSerialPort::ReadWrite);
	cv::VideoCapture capture;
	capture.open ("vip_car.avi");
	cv::Mat frame;
	cv::Mat des (240, 320, CV_8UC3);
	QByteArray arr[100][240];
	int f = 0;
	for (int i = 0; i < 100; ++i)for (int j = 0; j < 240; ++j)
		arr[i][j].resize (320 * 2 + 2);
	while (1) {
		capture >> frame;
		if (frame.empty ()) break;
		cv::resize (frame, des, des.size (), (0, 0), (0, 0), cv::INTER_CUBIC);
		for (int i = 0; i < 240; ++i) {
			for (int j = 0; j < 320; ++j) {
				uchar B = des.at<cv::Vec3b> (i, j)[0];
				uchar G = des.at<cv::Vec3b> (i, j)[1];
				uchar R = des.at<cv::Vec3b> (i, j)[2];
				arr[f][i][j * 2] = (R & 0xF8) | (G >> 5);
				arr[f][i][j * 2 + 1] = ((G & 0xFC) << 3) | (B >> 3);
			}
			arr[f][i][640] = 0x0D;
			arr[f][i][641] = 0x0A;
		}

		cv::imshow ("Example2", des);
		cvWaitKey (30);
		++f;
	}
	int i = f = 0;
	QObject::connect (&timer, &QTimer::timeout, [&](void) {
		if (i == 239) {
			sp.write (arr[f][i], 642);
			i = 0;
			++f;
		}
		else {
			sp.write (arr[f][i], 640);
			++i;
		}
		if (f == 100) timer.stop ();
	});
	timer.start ();
	return a.exec ();
}