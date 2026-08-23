#include "wireframecanvas.h"
#include <QPainter>
#include <QPen>
#include <cmath>

WireframeCanvas::WireframeCanvas(QQuickItem* parent)
    : QQuickPaintedItem(parent), m_time(0.0) {
    setAntialiasing(true);
    buildPyramid();
    buildCylinder();
    buildCube();
}

qreal WireframeCanvas::time() const {
    return m_time;
}

void WireframeCanvas::setTime(qreal t) {
    if (qFuzzyCompare(m_time, t)) return;
    m_time = t;
    emit timeChanged();
    update();
}

void WireframeCanvas::buildPyramid() {
    float h = 0.9f, half = 0.7f;
    m_verts3d = {
        {0, h, 0, 1},
        { half, -h,  half, 1},
        { half, -h, -half, 1},
        {-half, -h, -half, 1},
        {-half, -h,  half, 1}
    };
    m_edges = {
        {0,1},{0,2},{0,3},{0,4},
        {1,2},{2,3},{3,4},{4,1}
    };
}

void WireframeCanvas::buildCylinder() {
    float halfH = 1.2f, radius = 0.6f;
    int seg = 32;
    for (int i = 0; i < seg; ++i) {
        float a = 2.0f*(float)M_PI*(float)i/seg;
        m_verts3dCyl << Vec4{radius*cosf(a), -halfH, radius*sinf(a), 1};
        m_verts3dCyl << Vec4{radius*cosf(a),  halfH, radius*sinf(a), 1};
    }
    for (int i = 0; i < seg; ++i) {
        m_edgesCyl << QPair<int,int>(i*2,   (i*2+2)%(seg*2)); // bottom ring
        m_edgesCyl << QPair<int,int>(i*2+1, (i*2+3)%(seg*2)); // top ring
        m_edgesCyl << QPair<int,int>(i*2,   i*2+1);           // vertical struts
    }
}

void WireframeCanvas::buildCube() {
    float s = 0.7f;
    m_verts3dCube = {
        {-s,-s,-s,1}, { s,-s,-s,1}, { s, s,-s,1}, {-s, s,-s,1}, // back face (z-)
        {-s,-s, s,1}, { s,-s, s,1}, { s, s, s,1}, {-s, s, s,1}  // front face (z+)
    };
    m_edgesCube = {
        {0,1},{1,2},{2,3},{3,0},  // back
        {4,5},{5,6},{6,7},{7,4},  // front
        {0,4},{1,5},{2,6},{3,7}   // connectors
    };
}

void WireframeCanvas::paint(QPainter* painter) {
    const int w = width();
    const int h = height();

    painter->setRenderHint(QPainter::Antialiasing);

    float aspect = (float)w/(float)h;
    Matrix4 proj = Matrix4::perspective(45.0f*M_PI/180.0f, aspect, 0.1f, 100.0f);
    Matrix4 view = Matrix4::lookAt(0,0,6.5f, 0,0,0, 0,1,0);
    float t = (float)m_time;

    auto drawEdges = [&](const QVector<Vec4>& verts,
                         const QVector<QPair<int,int>>& edges,
                         const Matrix4& mvp) {
        for (auto& e : edges) {
            Vec4 pa = mvp.transform(verts[e.first]);  pa.x/=pa.w; pa.y/=pa.w;
            Vec4 pb = mvp.transform(verts[e.second]); pb.x/=pb.w; pb.y/=pb.w;
            painter->drawLine(QPointF((pa.x*0.5f+0.5f)*w, (1-(pa.y*0.5f+0.5f))*h),
                              QPointF((pb.x*0.5f+0.5f)*w, (1-(pb.y*0.5f+0.5f))*h));
        }
    };

    // Pyramid (orange)
    painter->setPen(QPen(QColor(250,180,60), 2.0f));
    drawEdges(m_verts3d, m_edges,
              proj * view * Matrix4::translate(-2.3f,0,0)
                * Matrix4::rotateY(t*1.1f) * Matrix4::rotateX(t*0.7f));

    // Cylinder (cyan)
    painter->setPen(QPen(QColor(80, 200, 255), 2.0f));
    drawEdges(m_verts3dCyl, m_edgesCyl,
              proj * view * Matrix4::translate(0,0,0)
                * Matrix4::rotateY(t*0.8f) * Matrix4::rotateX(t*0.5f));

    // Cube (red)
    painter->setPen(QPen(QColor(255, 70, 70), 2.0f));
    drawEdges(m_verts3dCube, m_edgesCube,
              proj * view * Matrix4::translate(2.3f,0,0)
                * Matrix4::rotateY(t*0.9f) * Matrix4::rotateX(t*0.6f));
}