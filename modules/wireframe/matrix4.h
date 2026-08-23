#pragma once
#include <cmath>
#include <cstring>

struct Vec4 {
    float x, y, z, w;
};

class Matrix4 {
public:
    float m[16];

    Matrix4() {
        for (int i = 0; i < 16; ++i) m[i] = 0.0f;
        m[0] = m[5] = m[10] = m[15] = 1.0f;
    }

    static Matrix4 perspective(float fov, float aspect, float near, float far) {
        Matrix4 mat;
        float f = 1.0f / tan(fov * 0.5f);
        mat.m[0] = f / aspect;
        mat.m[5] = f;
        mat.m[10] = (far + near) / (near - far);
        mat.m[11] = -1.0f;
        mat.m[14] = (2 * far * near) / (near - far);
        return mat;
    }

    static Matrix4 lookAt(float eyeX, float eyeY, float eyeZ,
                          float centerX, float centerY, float centerZ,
                          float upX, float upY, float upZ) {
        float z0 = eyeX - centerX;
        float z1 = eyeY - centerY;
        float z2 = eyeZ - centerZ;
        float len = sqrt(z0*z0 + z1*z1 + z2*z2);
        if (len == 0.0f) len = 1.0f;
        z0 /= len; z1 /= len; z2 /= len;

        float x0 = upY * z2 - upZ * z1;
        float x1 = upZ * z0 - upX * z2;
        float x2 = upX * z1 - upY * z0;
        len = sqrt(x0*x0 + x1*x1 + x2*x2);
        if (len == 0.0f) {
            if (fabs(upY) > fabs(upZ)) {
                x0 = -z1; x1 = 0; x2 = z0;
            } else {
                x0 = z1; x1 = -z0; x2 = 0;
            }
            len = sqrt(x0*x0 + x1*x1 + x2*x2);
            if (len == 0.0f) len = 1.0f;
        }
        x0 /= len; x1 /= len; x2 /= len;

        float y0 = z1 * x2 - z2 * x1;
        float y1 = z2 * x0 - z0 * x2;
        float y2 = z0 * x1 - z1 * x0;
        len = sqrt(y0*y0 + y1*y1 + y2*y2);
        if (len == 0.0f) len = 1.0f;
        y0 /= len; y1 /= len; y2 /= len;

        Matrix4 mat;
        mat.m[0] = x0; mat.m[1] = y0; mat.m[2] = z0; mat.m[3] = 0;
        mat.m[4] = x1; mat.m[5] = y1; mat.m[6] = z1; mat.m[7] = 0;
        mat.m[8] = x2; mat.m[9] = y2; mat.m[10] = z2; mat.m[11] = 0;
        mat.m[12] = -(x0*eyeX + x1*eyeY + x2*eyeZ);
        mat.m[13] = -(y0*eyeX + y1*eyeY + y2*eyeZ);
        mat.m[14] = -(z0*eyeX + z1*eyeY + z2*eyeZ);
        mat.m[15] = 1;
        return mat;
    }

    static Matrix4 rotateY(float angle) {
        Matrix4 mat;
        float c = cos(angle);
        float s = sin(angle);
        mat.m[0] = c;  mat.m[2] = -s;
        mat.m[5] = 1;
        mat.m[8] = s;  mat.m[10] = c;
        return mat;
    }

    static Matrix4 rotateX(float angle) {
        Matrix4 mat;
        float c = cos(angle);
        float s = sin(angle);
        mat.m[0] = 1;
        mat.m[5] = c;  mat.m[6] = -s;
        mat.m[9] = s;  mat.m[10] = c;
        return mat;
    }

    static Matrix4 translate(float x, float y, float z) {
        Matrix4 mat;
        mat.m[12] = x; mat.m[13] = y; mat.m[14] = z;
        return mat;
    }

    Vec4 transform(const Vec4& v) const {
        Vec4 r;
        r.x = m[0]*v.x + m[4]*v.y + m[8]*v.z  + m[12]*v.w;
        r.y = m[1]*v.x + m[5]*v.y + m[9]*v.z  + m[13]*v.w;
        r.z = m[2]*v.x + m[6]*v.y + m[10]*v.z + m[14]*v.w;
        r.w = m[3]*v.x + m[7]*v.y + m[11]*v.z + m[15]*v.w;
        return r;
    }

    Matrix4 operator*(const Matrix4& other) const {
        Matrix4 result;
        for (int i = 0; i < 4; ++i) {
            for (int j = 0; j < 4; ++j) {
                float sum = 0;
                for (int k = 0; k < 4; ++k) {
                    sum += m[k*4 + j] * other.m[i*4 + k];
                }
                result.m[i*4 + j] = sum;
            }
        }
        return result;
    }
};
