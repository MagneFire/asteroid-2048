import QtQuick 2.9
import Nemo.Configuration 1.0
import org.nemomobile.lipstick 0.1

Item {
    id: main
    anchors.fill: parent

    Item {
        id: logic

        property var score: 0
        property alias bestScore: bestScoreConf.value

        property var rows: 4
        property var cols: 4

        // The game field.
        property var cells: []

        // UI
        // Contains the empty grid cells
        // This is an array of indices.
        property var emptyGridCells: []

        ConfigurationValue {
            id: bestScoreConf
            key: "/2048/bestScore"
            defaultValue: 0
        }

        function movePossible() {
            for (var x=0; x<rows; x++) {
                for (var y=0; y<cols-1; y++) {
                    if (cells[x][y] == cells[x][y+1])
                        return true
                }
            }
            for (var x=0; x<rows-1; x++) {
                for (var y=0; y<cols; y++) {
                    if (cells[x][y] == cells[x+1][y])
                        return true
                }
            }
            return false
        }
        function moveCell(x1, y1, x2, y2) {
            var cell1 = cells[x1][y1];
            var cell2 = cells[x2][y2];

            // A cell cannot move over an existing cell with a different value.
            if ((cell1 !== 0 && cell2 !== 0) && cell1 !== cell2)
                return false

            // If can move to empty spot or spot with same value.
            if ((cell1 !== 0 && cell1 === cell2) || (cell1 !== 0 && cell2 === 0)) {
                cells[x1][y1] = 0;

                for (var i=0;i<logic.rows*logic.cols;i++) {
                    if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue
                    if ((cellsGrid.itemAt(i).x1 == x1) && (cellsGrid.itemAt(i).y1 == y1)) {
                        cellsGrid.itemAt(i).x1 = x2
                        cellsGrid.itemAt(i).y1 = y2
                        animationTimer.start()
                        break
                    }
                }
            }

            // Cell moves to position where same valued cell exists.
            if (cell1 !== 0 && cell1 === cell2) {
                cells[x2][y2] *= 2;
                score += cells[x2][y2]

                for (var i=0;i<logic.rows*logic.cols;i++) {
                    if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue
                    if ((cellsGrid.itemAt(i).x1 == x2) && (cellsGrid.itemAt(i).y1 == y2)) {
                        cellsGrid.itemAt(i).val = cells[x2][y2]
                        cellsGrid.itemAt(i).pop = true
                    }
                }
                return false;
            }

            // Cell moves to empty position.
            if (cell1 !== 0 && cell2 === 0) {
                cells[x2][y2] = cell1;
                return true;
            }
            return true
        }

        function move(gesture) {
            if (animationTimer.running) return

            if (gesture == "left" || gesture == "up") {
                for (var x=0; x<rows; x++) {
                    for (var y=0; y<cols; y++) {
                        for (var j= y+1; j<rows; j++) {
                            if (gesture == "left") {
                                if (!moveCell(j, x, y, x))
                                    break;
                            } else {
                                if (!moveCell(x, j, x, y))
                                    break;
                            }
                        }
                    }
                }
            }

            if (gesture == "right" || gesture == "down") {
                for (var x=0; x<rows; x++) {
                    for (var y=cols-1; y>=0; y--) {
                        for (var j= y-1; j>=0; j--) {
                            if (gesture == "right") {
                                if (!moveCell(j, x, y, x))
                                    break;
                            } else {
                                if (!moveCell(x, j, x, y))
                                    break;
                            }
                        }
                    }
                }
            }
        }

        function randCell() {
            var emptyCells = []
            for (var x=0; x<rows; x++) {
                for (var y=0; y<cols; y++) {
                    if (cells[x][y] == 0) {
                        emptyCells.push([x,y])
                    }
                }
            }
            if (!emptyCells.length) return

            var emptyCell = emptyCells[Math.floor(Math.random()*emptyCells.length)]
            var x = emptyCell[0]
            var y = emptyCell[1]
            cells[x][y] = (Math.random() < 0.9) ? 2 : 4

            // UI
            var emptyGrid = emptyGridCells[0]
            emptyGridCells.shift()

            cellsGrid.itemAt(emptyGrid).animateMove = false
            cellsGrid.itemAt(emptyGrid).val = cells[x][y]
            cellsGrid.itemAt(emptyGrid).x1 = x
            cellsGrid.itemAt(emptyGrid).y1 = y
            cellsGrid.itemAt(emptyGrid).animateMove = true

            if ((emptyCells.length<=1) && !movePossible()) {
                console.log("randCell::Moving is no longer possbile! GAME OVER!!")
                bestScore = Math.max(bestScore, score)
                gameOver.visible = true
            }
        }

        function removeDuplicateGridCells() {
            for (var i=0;i<rows*cols;i++) {
                if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue

                for (var j=i+1;j<rows*cols;j++) {
                    if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue
                    if ((cellsGrid.itemAt(i).x1 === cellsGrid.itemAt(j).x1) && (cellsGrid.itemAt(i).y1 === cellsGrid.itemAt(j).y1)) {
                        cellsGrid.itemAt(j).animateMove = false
                        cellsGrid.itemAt(j).val = 0
                        cellsGrid.itemAt(j).x1 = -1
                        cellsGrid.itemAt(j).y1 = -1
                        emptyGridCells[emptyGridCells.length] = j
                    }
                }
            }
        }

        function reset() {
            gameOver.visible = false
            for (var i=0;i<4;i++) {
                cells[i] = []
                for (var j=0;j<4;j++) {
                    cells[i][j] = 0
                }
            }
            score = 0
            for (var i=0;i<rows*cols;i++) {
                emptyGridCells[i] = i
                cellsGrid.itemAt(i).x1 = -1
                cellsGrid.itemAt(i).y1 = -1
                cellsGrid.itemAt(i).val = 0
            }
            randCell()
            randCell()
        }

        Timer {
            id: animationTimer
            interval: 200
            repeat: false
            onTriggered: {
                logic.removeDuplicateGridCells()
                logic.randCell()
            }
        }
    }

    Item {
        id: scoreBoard
        anchors.fill: parent

        opacity: 0.7

        Behavior on opacity { NumberAnimation { duration: 200 } }
        Rectangle {
            x: parent.width*0.35
            y: 0
            width: parent.width*0.3
            height: parent.height*0.12
            radius: 3
            color: "#af590b"

            Text {
                anchors.top: parent.top
                anchors.topMargin: parent.height*0.1
                width: parent.width
                color: "#eee4da"
                //% "SCORE"
                text: qsTrId("id-score")
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
            }
            Text {
                anchors.top: parent.top
                anchors.topMargin: parent.height*0.4
                width: parent.width
                color: "#fff"
                text: logic.score
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 20
            }
        }

        Rectangle {
            x: parent.width*0.35
            y: parent.height*0.88
            width: parent.width*0.3
            height: parent.height*0.12
            radius: 3
            color: "#af590b"

            Text {
                anchors.top: parent.top
                anchors.topMargin: parent.height*0.1
                width: parent.width
                color: "#fff"
                text: logic.bestScore
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 20
            }
            Text {
                anchors.top: parent.top
                anchors.topMargin: parent.height*0.6
                width: parent.width
                color: "#eee4da"
                //% "BEST"
                text: qsTrId("id-best")
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
            }
        }
    }

    Item {
        id: board
        property int fieldWidth: Math.floor(Math.sqrt(Math.pow(parent.width, 2)/2))
        property int fieldHeight: Math.floor(Math.sqrt(Math.pow(parent.height, 2)/2))
        property int fieldMarginWidth: (parent.width-fieldWidth)/2
        property int fieldMarginHeight: (parent.height-fieldHeight)/2

        anchors {
            right: parent.right;
            left: parent.left;
            bottom: parent.bottom;
            top: parent.top;
            leftMargin: fieldMarginWidth;
            rightMargin: fieldMarginWidth;
            topMargin: fieldMarginHeight;
            bottomMargin: fieldMarginHeight;
        }

        Grid {
            id: grid
            anchors.fill: parent
            columns: 4
            rows: 4
            opacity: 0.7

            Repeater {
                model: grid.columns * grid.rows

                Rectangle {
                    width: grid.width/grid.columns
                    height: grid.height/grid.rows
                    color: "#af590b"

                    Rectangle {
                        radius: 3
                        anchors.fill: parent
                        color: "#60eee4da"
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                    }
                }
            }
        }

        Repeater {
            id: cellsGrid
            model: grid.columns * grid.rows

            Rectangle {
                property bool animateMove: true
                property int x1: -1
                property int y1: -1
                property int val: 0
                property bool pop: false
                property int prevScale: 0
                width: grid.width/grid.columns - 10
                height: grid.height/grid.rows - 10
                x: 5 + x1*(grid.width/grid.columns)
                y: 5 + y1*(grid.height/grid.rows)
                color: val == 2    ? "#eee4da" :
                       val == 4    ? "#ede0c8" :
                       val == 8    ? "#f2b179" :
                       val == 16   ? "#f59563" :
                       val == 32   ? "#f67c5f" :
                       val == 64   ? "#f65e3b" :
                       val == 128  ? "#edcf72" :
                       val == 256  ? "#edcc61" :
                       val == 512  ? "#edc850" :
                       val == 1024 ? "#edc53f" :
                                     "#edc22e" // 2048
                scale: val ? (pop ? 1.1 : 1) : 0
                radius: 3
                visible: ((x1 != -1) && (y1 !=-1))
                onScaleChanged: if (scale >= 1.1) pop = false

                Behavior on x { enabled: animateMove; NumberAnimation { duration: 100} }
                Behavior on y { enabled: animateMove; NumberAnimation { duration: 100} }
                Behavior on scale { NumberAnimation { duration: 100} }
                Text {
                    anchors.fill: parent
                    color: val <= 4 ? "#776e65" : "#f9f6f2"
                    text: parent.val
                    scale: parent.scale
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: val <= 9    ? height :
                                    val <= 99   ? height*0.7 :
                                    val <= 999  ? height*0.5 :
                                                  height*0.4
                }
            }
        }
    }

    MouseArea {
        width: board.width
        height: board.height
        anchors.centerIn: board

        property bool swipeMode: true

        property int threshold: width*0.01
        property string gesture: ""
        property int value: 0
        property bool horizontal: false

        property int initialX: 0
        property int initialY: 0
        property int deltaX: 0
        property int deltaY: 0

        onPressed: {
            gesture = ""
            value = 0
            initialX = 0
            initialY = 0
            deltaX = 0
            deltaY = 0
            initialX = mouse.x
            initialY = mouse.y
        }

        onPositionChanged: {
            deltaX = mouse.x - initialX
            deltaY = mouse.y - initialY
            horizontal = Math.abs(deltaX) > Math.abs(deltaY)
            if (horizontal) value = deltaX
            else value = deltaY
        }

        onReleased: {
            if (!swipeMode) {
                var centerY = initialY - board.height/2
                var centerX = initialX - board.width/2
                horizontal = Math.abs(centerX) > Math.abs(centerY)
                if (horizontal) value = centerX
                else value = centerY
            }
            if (value > threshold && horizontal) {
                gesture = "right"
            } else if (value < -threshold && horizontal) {
                gesture = "left"
            } else if (value > threshold) {
                gesture = "down"
            } else if (value < -threshold) {
                gesture = "up"
            } else {
                return
            }
            logic.move(gesture)
        }
    }

    Rectangle {
        property string gesture: ""
        focus: true

        Keys.onPressed: {
            event.accepted = true
            if (event.key == Qt.Key_Right) {
                gesture = "right"
            } else if (event.key == Qt.Key_Left) {
                gesture = "left"
            } else if (event.key == Qt.Key_Down) {
                gesture = "down"
            } else if (event.key == Qt.Key_Up) {
                gesture = "up"
            } else {
                return
            }
            logic.move(gesture)
        }
    }

    Rectangle {
        id: gameOver
        anchors.fill: parent
        visible: false
        opacity: visible ? 0.8 : 0.0

        Behavior on opacity { NumberAnimation { duration: 200 } }
        Text {
            anchors.top: parent.top
            width: parent.width
            height: parent.height*0.7
            color: "#776e65"
            //% "Game Over"
            text: qsTrId("id-game-over")
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: parent.height/text.length
        }
        Rectangle {
            color: "#8f7a66"
            x: parent.width*0.3
            y: parent.height*0.5
            width: parent.width*0.4
            height: parent.height*0.15

            Text {
                anchors.top: parent.top
                width: parent.width
                height: parent.height
                color: "#f9f6f2"
                //% "Try Again"
                text: qsTrId("id-try-again")
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: parent.height*0.4
            }
            MouseArea {
                width: parent.width
                height: parent.height
                anchors.centerIn: parent
                onClicked: logic.reset()
            }
        }
    }

    Component.onCompleted: {
        logic.reset()
    }
}