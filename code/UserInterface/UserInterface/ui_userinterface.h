/********************************************************************************
** Form generated from reading UI file 'userinterface.ui'
**
** Created by: Qt User Interface Compiler version 5.9.1
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_USERINTERFACE_H
#define UI_USERINTERFACE_H

#include <QtCore/QVariant>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QButtonGroup>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QToolBar>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_UserInterfaceClass
{
public:
    QMenuBar *menuBar;
    QToolBar *mainToolBar;
    QWidget *centralWidget;
    QStatusBar *statusBar;

    void setupUi(QMainWindow *UserInterfaceClass)
    {
        if (UserInterfaceClass->objectName().isEmpty())
            UserInterfaceClass->setObjectName(QStringLiteral("UserInterfaceClass"));
        UserInterfaceClass->resize(600, 400);
        menuBar = new QMenuBar(UserInterfaceClass);
        menuBar->setObjectName(QStringLiteral("menuBar"));
        UserInterfaceClass->setMenuBar(menuBar);
        mainToolBar = new QToolBar(UserInterfaceClass);
        mainToolBar->setObjectName(QStringLiteral("mainToolBar"));
        UserInterfaceClass->addToolBar(mainToolBar);
        centralWidget = new QWidget(UserInterfaceClass);
        centralWidget->setObjectName(QStringLiteral("centralWidget"));
        UserInterfaceClass->setCentralWidget(centralWidget);
        statusBar = new QStatusBar(UserInterfaceClass);
        statusBar->setObjectName(QStringLiteral("statusBar"));
        UserInterfaceClass->setStatusBar(statusBar);

        retranslateUi(UserInterfaceClass);

        QMetaObject::connectSlotsByName(UserInterfaceClass);
    } // setupUi

    void retranslateUi(QMainWindow *UserInterfaceClass)
    {
        UserInterfaceClass->setWindowTitle(QApplication::translate("UserInterfaceClass", "UserInterface", Q_NULLPTR));
    } // retranslateUi

};

namespace Ui {
    class UserInterfaceClass: public Ui_UserInterfaceClass {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_USERINTERFACE_H
