import QtQuick 2.9

Item {
    id: main
    anchors.fill: parent

    Item {
        id: logic

        property var score: 0

        property var rows: 4
        property var cols: 4

        // The game field.
        property var cells: []

        // UI
        // Contains the empty grid cells
        // This is an array of indices.
        property var emptyGridCells: []

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
                //console.log("moving: " + x1 + " y: "  + y1)

                for (var i=0;i<logic.rows*logic.cols;i++) {
                    if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue
                    if ((cellsGrid.itemAt(i).x1 == x1) && (cellsGrid.itemAt(i).y1 == y1)) {
                        cellsGrid.itemAt(i).x1 = x2
                        cellsGrid.itemAt(i).y1 = y2
                        animationTimer.start()
                        //console.log("FOUND: " + i +" x: " + x1 + "->" + x2 +" y: " + y1 + "->" + y2)
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
                //console.log("moveCell::Score: " + score)
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
            if (!emptyCells.length) {
                //console.log("ERR!:randCell:: No more empty cells available!")
                return
            }

            var emptyCell = emptyCells[Math.floor(Math.random()*emptyCells.length)]
            var x = emptyCell[0]
            var y = emptyCell[1]
            cells[x][y] = (Math.random() < 0.9) ? 2 : 4

            // UI
            var emptyGrid = emptyGridCells[0]
            emptyGridCells.shift()
            //console.log("randCell::Using random cell: " + emptyCell + " x: " + x + " y: " + y + " value: " + cells[x][y] + " id: " + emptyGrid)

            cellsGrid.itemAt(emptyGrid).animateMove = false
            cellsGrid.itemAt(emptyGrid).val = cells[x][y]
            cellsGrid.itemAt(emptyGrid).x1 = x
            cellsGrid.itemAt(emptyGrid).y1 = y
            cellsGrid.itemAt(emptyGrid).animateMove = true

            //console.log("randCell::Empty cells left: " + (emptyCells.length-1))

            if ((emptyCells.length<=1) && !movePossible()) {
                console.log("randCell::Moving is no longer possbile! GAME OVER!!")
            }
        }

        function removeDuplicateGridCells() {
            for (var i=0;i<rows*cols;i++) {
                if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue

                for (var j=i+1;j<rows*cols;j++) {
                    if ((cellsGrid.itemAt(i).x1 == -1) || (cellsGrid.itemAt(i).y1 == -1)) continue
                    if ((cellsGrid.itemAt(i).x1 === cellsGrid.itemAt(j).x1) && (cellsGrid.itemAt(i).y1 === cellsGrid.itemAt(j).y1)) {
                        //console.log("onTriggered:: FOUND DUPE i: " + j + " x: " + cellsGrid.itemAt(j).x1 + " y: " + cellsGrid.itemAt(j).y1 + " v: " + cellsGrid.itemAt(j).children[0].text)
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
            //console.log("reset::Loading game...")
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
                /*for (var i=0;i<4;i++) {
                    console.log("\t" + logic.cells[0][i] + "\t" + 
                                logic.cells[1][i] + "\t" + 
                                logic.cells[2][i] + "\t" + 
                                logic.cells[3][i] + "\t")
                }*/
            }
        }

        Component.onCompleted: reset()
    }

    Rectangle {
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

        color: "#bbada0"
        //color: "transparent"

        Grid {
            id: grid
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            columns: 4
            rows: 4
            Repeater {
                model: grid.columns * grid.rows
                Rectangle {
                    width: grid.width/grid.columns
                    height: grid.height/grid.rows
                    color: "#bbada0"
                    //color: "transparent"
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
            property var backgrounds: {}
            Rectangle {
                property bool animateMove: true
                property int x1: -1
                property int y1: -1
                property int val: 0
                property bool pop: false
                property int prevScale: 0
                width: grid.width/grid.columns - 10
                height: grid.height/grid.rows - 10
                x: 10 + x1*(grid.width/grid.columns)
                y: 10 + y1*(grid.height/grid.rows)
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
                onScaleChanged: if (scale >= 1.1) pop = false
                radius: 3
                Behavior on x { enabled: animateMove; NumberAnimation { duration: 100} }
                Behavior on y { enabled: animateMove; NumberAnimation { duration: 100} }
                Behavior on scale { NumberAnimation { duration: 100} }
                Text {
                    id: lbl
                    anchors.fill: parent
                    color: val <= 4 ? "#000" : "#f9f6f2"
                    text: parent.val
                    scale: parent.scale
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        MouseArea {
            width: parent.width
            height: parent.height
            anchors.centerIn: parent

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
                    var centerY = initialY - parent.height/2
                    var centerX = initialX - parent.width/2
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

        Rectangle{
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
    }
}