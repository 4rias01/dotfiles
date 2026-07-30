// ════════════════════════════════════════════════════════════════
//  LoginForm.qml — usuario, contrasena, boton y selector de sesion.
//  Es la unica parte del tema que habla con el objeto `sddm`.
// ════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Controls

Column {
    id: form

    property string fontFamily: "Sans"
    property string iconFont: "Sans"
    property int textSize: 10
    property int iconSize: 12
    property int fieldHeight: 42
    property color fieldColor: "#2a2d3a"
    property color fieldTextColor: "#ffffff"
    property color placeholderColor: "#a0a4b8"
    property color buttonColor: "#343746"
    property color buttonTextColor: "#ffffff"
    property color warningColor: "#e78284"
    property color accentColor: "#b7cef1"

    // Mensaje de error. Ojo: NO se asigna directo a warning.text porque
    // eso romperia el binding que tambien muestra el aviso de Bloq Mayus.
    // Se usa una propiedad intermedia y el Text elige que mostrar.
    property string message: ""

    spacing: 10

    function doLogin() {
        form.message = ""
        // La firma real es login(usuario, password, indiceDeSesion).
        sddm.login(username.text, password.text, session.currentIndex)
    }

    Field {
        id: username
        width: parent.width
        height: form.fieldHeight
        glyph: "\uf007" // nf-fa-user
        placeholderText: "Usuario"
        text: userModel.lastUser

        fontFamily: form.fontFamily
        iconFont: form.iconFont
        textSize: form.textSize
        iconSize: form.iconSize
        bgColor: form.fieldColor
        fgColor: form.fieldTextColor
        phColor: form.placeholderColor

        onAccepted: password.forceActiveFocus()
        KeyNavigation.tab: password
    }

    Field {
        id: password
        width: parent.width
        height: form.fieldHeight
        glyph: "\uf023" // nf-fa-lock
        placeholderText: "Contrasena"
        echoMode: TextInput.Password
        passwordCharacter: "\u2022"
        focus: true // arranca con el cursor aca

        fontFamily: form.fontFamily
        iconFont: form.iconFont
        textSize: form.textSize
        iconSize: form.iconSize
        bgColor: form.fieldColor
        fgColor: form.fieldTextColor
        phColor: form.placeholderColor

        onAccepted: form.doLogin() // Enter = login
        KeyNavigation.tab: username
    }

    Item { width: 1; height: 12 }

    Button {
        id: loginButton
        width: parent.width
        height: form.fieldHeight
        onClicked: form.doLogin()

        background: Rectangle {
            radius: height / 2
            color: loginButton.pressed
                   ? Qt.darker(form.buttonColor, 1.3)
                   : (loginButton.hovered
                      ? Qt.lighter(form.buttonColor, 1.25)
                      : form.buttonColor)
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        contentItem: Text {
            text: "Login"
            color: form.buttonTextColor
            font.family: form.fontFamily
            font.pointSize: form.textSize
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Text {
        id: warning
        width: parent.width
        height: 18
        horizontalAlignment: Text.AlignHCenter
        color: form.warningColor
        font.family: form.fontFamily
        font.pointSize: form.textSize - 1
        text: form.message !== ""
              ? form.message
              : (keyboard.capsLock ? "Bloq Mayus activado" : "")
    }

    // Selector de sesion. Un ComboBox sin indicador ni fondo, para que
    // parezca solo texto clickeable como en la captura original.
    // El popup que se abre usa el estilo por defecto de Qt: estilizarlo
    // es un buen ejercicio para mas adelante.
    ComboBox {
        id: session
        width: parent.width
        height: 24
        model: sessionModel
        textRole: "name"
        currentIndex: sessionModel.lastIndex

        indicator: null
        background: Item {}

        contentItem: Text {
            text: "Session (" + session.displayText + ")"
            color: session.hovered ? form.accentColor : form.buttonTextColor
            font.family: form.fontFamily
            font.pointSize: form.textSize - 1
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    // Connections escucha senales de un objeto que no es hijo de este.
    // En Qt6 los handlers se escriben como function onNombreDeSenal().
    Connections {
        target: sddm

        function onLoginFailed() {
            form.message = "Usuario o contrasena incorrectos"
            password.text = ""
            password.forceActiveFocus()
        }

        function onLoginSucceeded() {
            form.message = ""
        }
    }
}
