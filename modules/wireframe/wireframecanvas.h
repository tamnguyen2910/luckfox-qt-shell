#pragma once
#include <QQuickPaintedItem>
#include <QVector>
#include <QPair>
#include <QColor>
#include "matrix4.h"

// Renderer for the 3D wireframe scene (ported from 04_demo / 05_wireframe).
// UI (labels, animation) lives in QML; this item only paints the projected
// wireframe shapes — pyramid, cylinder, cube.
class WireframeCanvas : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(qreal time READ time WRITE setTime NOTIFY timeChanged)

public:
    explicit WireframeCanvas(QQuickItem* parent = nullptr);

    qreal time() const;
    void setTime(qreal t);

    void paint(QPainter* painter) override;

signals:
    void timeChanged();

private:
    qreal m_time;

    QVector<Vec4> m_verts3d;
    QVector<QPair<int,int>> m_edges;
    QVector<Vec4> m_verts3dCyl;
    QVector<QPair<int,int>> m_edgesCyl;
    QVector<Vec4> m_verts3dCube;
    QVector<QPair<int,int>> m_edgesCube;

    void buildPyramid();
    void buildCylinder();
    void buildCube();
};