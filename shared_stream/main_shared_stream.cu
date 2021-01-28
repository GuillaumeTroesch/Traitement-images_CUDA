#include <opencv2/opencv.hpp>
#include <vector>
#include <iostream>
#include <string>

#define taille_stream 2
std::size_t taille_rgb = 0;
std::size_t one_line_rgb = 0;


__global__ void blur2D(const unsigned char* rgb_in, unsigned char* rgb_out_blur, int rows, int cols) {
    auto col = blockIdx.x * blockDim.x + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * blockDim.y + threadIdx.y; //pos de la couleur sur y

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_blur2D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        for (int rgb = 0; rgb < 3; ++rgb) {
            unsigned char hg = rgb_in[3 * ((row - 1) * cols + col - 1) + rgb];
            unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
            unsigned char hd = rgb_in[3 * ((row - 1) * cols + col + 1) + rgb];
            unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
            unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
            unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
            unsigned char bg = rgb_in[3 * ((row + 1) * cols + col - 1) + rgb];
            unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
            unsigned char bd = rgb_in[3 * ((row + 1) * cols + col + 1) + rgb];

            sh_blur2D[3 * (lrow * blockDim.x + lcol) + rgb] = (hg + h + hd + g + c + d + bg + b + bd) / 9;
            rgb_out_blur[3 * (row * cols + col) + rgb] = sh_blur2D[3 * (lrow * blockDim.x + lcol) + rgb];
        }
    }
}

__global__ void sharpen2D(const unsigned char* rgb_in, unsigned char* rgb_out_sharpen, int rows, int cols) {
    auto col = blockIdx.x * blockDim.x + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * blockDim.y + threadIdx.y; //pos de la couleur sur y

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_sharpen_2D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        for (int rgb = 0; rgb < 3; ++rgb) {
            unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
            unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
            unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
            unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
            unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
            int somme = (-3 * (h + g + d + b) + 21 * c) / 9;

            if (somme > 255) somme = 255;
            if (somme < 0) somme = 0;

            sh_sharpen_2D[3 * (lrow * blockDim.x + lcol) + rgb] = somme;
            rgb_out_sharpen[3 * (row * cols + col) + rgb] = sh_sharpen_2D[3 * (lrow * blockDim.x + lcol) + rgb];
        }
    }
}

__global__ void edge_detect2D(const unsigned char* rgb_in, unsigned char* rgb_out_edge_detect, int rows, int cols) {
    auto col = blockIdx.x * blockDim.x + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * blockDim.y + threadIdx.y; //pos de la couleur sur y

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_edge_detect_2D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        for (int rgb = 0; rgb < 3; ++rgb) {
            unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
            unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
            unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
            unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
            unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
            int somme = (9 * (h + g + d + b) - 36 * c) / 9;

            if (somme > 255) somme = 255;
            if (somme < 0) somme = 0;

            sh_edge_detect_2D[3 * (lrow * blockDim.x + lcol) + rgb] = somme;
            rgb_out_edge_detect[3 * (row * cols + col) + rgb] = sh_edge_detect_2D[3 * (lrow * blockDim.x + lcol) + rgb];
        }
    }
}


__global__ void blur3D(const unsigned char* rgb_in, unsigned char* rgb_out_blur, int rows, int cols) {
    auto col = blockIdx.x * blockDim.x + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * blockDim.y + threadIdx.y; //pos de la couleur sur y
    auto rgb = threadIdx.z;

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_blur3D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        unsigned char hg = rgb_in[3 * ((row - 1) * cols + col - 1) + rgb];
        unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
        unsigned char hd = rgb_in[3 * ((row - 1) * cols + col + 1) + rgb];
        unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
        unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
        unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
        unsigned char bg = rgb_in[3 * ((row + 1) * cols + col - 1) + rgb];
        unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
        unsigned char bd = rgb_in[3 * ((row + 1) * cols + col + 1) + rgb];

        sh_blur3D[3*(lrow * blockDim.x + lcol) + rgb] = (hg + h + hd + g + c + d + bg + b + bd) / 9;
        rgb_out_blur[3 * (row * cols + col) + rgb] = sh_blur3D[3 * (lrow * blockDim.x + lcol) + rgb];
    }
}

__global__ void sharpen3D(const unsigned char* rgb_in, unsigned char* rgb_out_sharpen, int rows, int cols) {
    auto col = blockIdx.x * blockDim.x + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * blockDim.y + threadIdx.y; //pos de la couleur sur y
    auto rgb = threadIdx.z;

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_sharpen3D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
        unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
        unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
        unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
        unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
        int somme = (-3 * (h + g + d + b) + 21 * c) / 9;

        if (somme > 255) somme = 255;
        if (somme < 0) somme = 0;

        sh_sharpen3D[3 * (lrow * blockDim.x + lcol) + rgb] = somme;
        rgb_out_sharpen[3 * (row * cols + col) + rgb] = sh_sharpen3D[3 * (lrow * blockDim.x + lcol) + rgb];
    }
}

__global__ void edge_detect3D(const unsigned char* rgb_in, unsigned char* rgb_out_edge_detect, int rows, int cols) {
    auto col = blockIdx.x * blockDim.x + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * blockDim.y + threadIdx.y; //pos de la couleur sur y
    auto rgb = threadIdx.z;

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_edge_detect3D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
        unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
        unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
        unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
        unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
        int somme = (9 * (h + g + d + b) - 36 * c) / 9;

        if (somme > 255) somme = 255;
        if (somme < 0) somme = 0;

        sh_edge_detect3D[3*(lrow * blockDim.x + lcol) + rgb] = somme;
        rgb_out_edge_detect[3 * (row * cols + col) + rgb] = sh_edge_detect3D[3*(lrow * blockDim.x + lcol) + rgb];
    }
}


__global__ void blur_edge_detect2D(const unsigned char * rgb_in, unsigned char * rgb_out_edge_detect, std::size_t rows, std::size_t cols) {
    auto col = blockIdx.x * (blockDim.x - 2) + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * (blockDim.y - 2) + threadIdx.y; //pos de la couleur sur y

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_blur_edge_detect2D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        for (int rgb = 0; rgb < 3; ++rgb) {
            unsigned char hg = rgb_in[3 * ((row - 1) * cols + col - 1) + rgb];
            unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
            unsigned char hd = rgb_in[3 * ((row - 1) * cols + col + 1) + rgb];
            unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
            unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
            unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
            unsigned char bg = rgb_in[3 * ((row + 1) * cols + col - 1) + rgb];
            unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
            unsigned char bd = rgb_in[3 * ((row + 1) * cols + col + 1) + rgb];

            sh_blur_edge_detect2D[3 * (lrow * blockDim.x + lcol) + rgb] = (hg + h + hd + g + c + d + bg + b + bd) / 9;
        }
    } else {
        for (int rgb = 0; rgb < 3; ++rgb) {
            sh_blur_edge_detect2D[3 * (lrow * blockDim.x + lcol) + rgb] = 0;
        }
    }

    __syncthreads();

    auto ww = blockDim.x;

    if (lcol > 0 && lcol < (blockDim.x - 1) && lrow > 0 && lrow < (blockDim.y - 1) &&
        row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        for (int rgb = 0; rgb < 3; ++rgb) {
            unsigned char h = sh_blur_edge_detect2D[3 * ((lrow - 1) * ww + lcol) + rgb];
            unsigned char g = sh_blur_edge_detect2D[3 * (lrow * ww + lcol - 1) + rgb];
            unsigned char c = sh_blur_edge_detect2D[3 * (lrow * ww + lcol) + rgb];
            unsigned char d = sh_blur_edge_detect2D[3 * (lrow * ww + lcol + 1) + rgb];
            unsigned char b = sh_blur_edge_detect2D[3 * ((lrow + 1) * ww + lcol) + rgb];
            int somme = (9 * (h + g + d + b) - 36 * c) / 9;

            if (somme > 255) somme = 255;
            if (somme < 0) somme = 0;

            rgb_out_edge_detect[3 * (row * cols + col) + rgb] = somme;
        }
    }
}

__global__ void edge_detect_blur2D(const unsigned char * rgb_in, unsigned char * rgb_out_edge_detect, std::size_t rows, std::size_t cols) {
    auto col = blockIdx.x * (blockDim.x - 2) + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * (blockDim.y - 2) + threadIdx.y; //pos de la couleur sur y

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_edge_detect_blur2D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        for (int rgb = 0; rgb < 3; ++rgb) {
            unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
            unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
            unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
            unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
            unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
            int somme = (9 * (h + g + d + b) - 36 * c) / 9;

            if (somme > 255) somme = 255;
            if (somme < 0) somme = 0;

            sh_edge_detect_blur2D[3 * (lrow * blockDim.x + lcol) + rgb] = somme;
        }
    } else {
        for (int rgb = 0; rgb < 3; ++rgb) {
            sh_edge_detect_blur2D[3 * (lrow * blockDim.x + lcol) + rgb] = 0;
        }
    }

    __syncthreads();

    auto ww = blockDim.x;

    if (lcol > 0 && lcol < (blockDim.x - 1) && lrow > 0 && lrow < (blockDim.y - 1) &&
        row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        for (int rgb = 0; rgb < 3; ++rgb) {
            unsigned char hg = sh_edge_detect_blur2D[3 * ((lrow - 1) * ww + lcol - 1) + rgb];
            unsigned char h = sh_edge_detect_blur2D[3 * ((lrow - 1) * ww + lcol) + rgb];
            unsigned char hd = sh_edge_detect_blur2D[3 * ((lrow - 1) * ww + lcol + 1) + rgb];
            unsigned char g = sh_edge_detect_blur2D[3 * (lrow * ww + lcol - 1) + rgb];
            unsigned char c = sh_edge_detect_blur2D[3 * (lrow * ww + lcol) + rgb];
            unsigned char d = sh_edge_detect_blur2D[3 * (lrow * ww + lcol + 1) + rgb];
            unsigned char bg = sh_edge_detect_blur2D[3 * ((lrow + 1) * ww + lcol - 1) + rgb];
            unsigned char b = sh_edge_detect_blur2D[3 * ((lrow + 1) * ww + lcol) + rgb];
            unsigned char bd = sh_edge_detect_blur2D[3 * ((lrow + 1) * ww + lcol + 1) + rgb];

            rgb_out_edge_detect[3 * (row * cols + col) + rgb] = (hg + h + hd + g + c + d + bg + b + bd) / 9;
        }
    }
}


__global__ void blur_edge_detect3D(const unsigned char * rgb_in, unsigned char * rgb_out_blur_edge_detect, std::size_t rows, std::size_t cols) {
    auto col = blockIdx.x * (blockDim.x - 2) + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * (blockDim.y - 2) + threadIdx.y; //pos de la couleur sur y
    auto rgb = threadIdx.z;

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_blur_edge_detect3D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        unsigned char hg = rgb_in[3 * ((row - 1) * cols + col - 1) + rgb];
        unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
        unsigned char hd = rgb_in[3 * ((row - 1) * cols + col + 1) + rgb];
        unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
        unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
        unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
        unsigned char bg = rgb_in[3 * ((row + 1) * cols + col - 1) + rgb];
        unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
        unsigned char bd = rgb_in[3 * ((row + 1) * cols + col + 1) + rgb];

        sh_blur_edge_detect3D[3 * (lrow * blockDim.x + lcol) + rgb] = (hg + h + hd + g + c + d + bg + b + bd) / 9;
    } else {
        sh_blur_edge_detect3D[3 * (lrow * blockDim.x + lcol) + rgb] = 0;
    }

    __syncthreads();

    auto ww = blockDim.x;

    if (lcol > 0 && lcol < (blockDim.x - 1) && lrow > 0 && lrow < (blockDim.y - 1) &&
        row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        unsigned char h = sh_blur_edge_detect3D[3 * ((lrow - 1) * ww + lcol) + rgb];
        unsigned char g = sh_blur_edge_detect3D[3 * (lrow * ww + lcol - 1) + rgb];
        unsigned char c = sh_blur_edge_detect3D[3 * (lrow * ww + lcol) + rgb];
        unsigned char d = sh_blur_edge_detect3D[3 * (lrow * ww + lcol + 1) + rgb];
        unsigned char b = sh_blur_edge_detect3D[3 * ((lrow + 1) * ww + lcol) + rgb];
        int somme = (9 * (h + g + d + b) - 36 * c) / 9;

        if (somme > 255) somme = 255;
        if (somme < 0) somme = 0;

        rgb_out_blur_edge_detect[3 * (row * cols + col) + rgb] = somme;
    }
}

__global__ void edge_detect_blur3D(const unsigned char * rgb_in, unsigned char * rgb_out_edge_detect_blur, std::size_t rows, std::size_t cols) {
    auto col = blockIdx.x * (blockDim.x - 2) + threadIdx.x; //pos de la couleur sur x
    auto row = blockIdx.y * (blockDim.y - 2) + threadIdx.y; //pos de la couleur sur y
    auto rgb = threadIdx.z;

    auto lcol = threadIdx.x;
    auto lrow = threadIdx.y;

    extern __shared__ unsigned char sh_edge_detect_blur3D[];

    if (row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
        unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
        unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
        unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
        unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
        int somme = (9 * (h + g + d + b) - 36 * c) / 9;

        if (somme > 255) somme = 255;
        if (somme < 0) somme = 0;

        sh_edge_detect_blur3D[3 * (lrow * blockDim.x + lcol) + rgb] = somme;
    } else {
        sh_edge_detect_blur3D[3 * (lrow * blockDim.x + lcol) + rgb] = 0;
    }

    __syncthreads();

    auto ww = blockDim.x;

    if (lcol > 0 && lcol < (blockDim.x - 1) && lrow > 0 && lrow < (blockDim.y - 1) &&
        row >= 1 && row < rows - 1 && col >= 1 && col < cols - 1) {
        unsigned char hg = sh_edge_detect_blur3D[3 * ((lrow - 1) * ww + lcol - 1) + rgb];
        unsigned char h = sh_edge_detect_blur3D[3 * ((lrow - 1) * ww + lcol) + rgb];
        unsigned char hd = sh_edge_detect_blur3D[3 * ((lrow - 1) * ww + lcol + 1) + rgb];
        unsigned char g = sh_edge_detect_blur3D[3 * (lrow * ww + lcol - 1) + rgb];
        unsigned char c = sh_edge_detect_blur3D[3 * (lrow * ww + lcol) + rgb];
        unsigned char d = sh_edge_detect_blur3D[3 * (lrow * ww + lcol + 1) + rgb];
        unsigned char bg = sh_edge_detect_blur3D[3 * ((lrow + 1) * ww + lcol - 1) + rgb];
        unsigned char b = sh_edge_detect_blur3D[3 * ((lrow + 1) * ww + lcol) + rgb];
        unsigned char bd = sh_edge_detect_blur3D[3 * ((lrow + 1) * ww + lcol + 1) + rgb];

        rgb_out_edge_detect_blur[3 * (row * cols + col) + rgb] = (hg + h + hd + g + c + d + bg + b + bd) / 9;
    }
}


void main_blur(const dim3 grid, const dim3 block, const unsigned int shared, const cudaStream_t* streams, const unsigned char* rgb_in,
               unsigned char* rgb_out_blur, int rows, int cols) {
    // Debut de chrono
    cudaEvent_t start;
    cudaEvent_t stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    // Appel kernel
    if (block.z == 1) {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            blur2D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage,
                    rgb_out_blur + decalage, row_stream, cols);
        }
    } else {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            blur3D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage, rgb_out_blur + decalage,
                    row_stream, cols);
        }
    }

    // Fin de chrono
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    std::cout << cudaGetErrorString(cudaGetLastError()) << std::endl;
    float elapsedTime;
    cudaEventElapsedTime(&elapsedTime, start, stop);
    std::cout << "blur_stream_" << block.x << "-" << block.y << "-" << block.z << ": " << elapsedTime << std::endl;
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}

void main_sharpen(const dim3 grid, const dim3 block, const unsigned int shared, const cudaStream_t* streams, const unsigned char* rgb_in,
                  unsigned char* rgb_out_sharpen, int rows, int cols) {
    // Debut de chrono
    cudaEvent_t start;
    cudaEvent_t stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    // Appel kernel
    if (block.z == 1) {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            sharpen2D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage,
                    rgb_out_sharpen + decalage, row_stream, cols);
        }
    } else {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            sharpen3D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage, rgb_out_sharpen + decalage,
                    row_stream, cols);
        }
    }

    // Fin de chrono
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    std::cout << cudaGetErrorString(cudaGetLastError()) << std::endl;
    float elapsedTime;
    cudaEventElapsedTime(&elapsedTime, start, stop);
    std::cout << "sharpen_stream_" << block.x << "-" << block.y << "-" << block.z << ": " << elapsedTime << std::endl;
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}

void main_edge_detect(const dim3 grid, const dim3 block, const unsigned int shared, const cudaStream_t* streams, const unsigned char* rgb_in,
                      unsigned char* rgb_out_edge_detect, int rows, int cols) {
    // Debut de chrono
    cudaEvent_t start;
    cudaEvent_t stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    // Appel kernel
    if (block.z == 1) {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            edge_detect2D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage,
                    rgb_out_edge_detect + decalage, row_stream, cols);
        }
    } else {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            edge_detect3D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage,
                    rgb_out_edge_detect + decalage, row_stream, cols);
        }
    }

    // Fin de chrono
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    std::cout << cudaGetErrorString(cudaGetLastError()) << std::endl;
    float elapsedTime;
    cudaEventElapsedTime(&elapsedTime, start, stop);
    std::cout << "edge_detect_stream_" << block.x << "-" << block.y << "-" << block.z << ": " << elapsedTime << std::endl;
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}


void main_blur_edge_detect(const dim3 grid, const dim3 block, const unsigned int shared, const cudaStream_t* streams, const unsigned char* rgb_in,
        unsigned char* rgb_tmp_blur_edge_detect, unsigned char* rgb_out_blur_edge_detect, int rows, int cols) {
    // Debut de chrono
    cudaEvent_t start;
    cudaEvent_t stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    // Appel kernel
    if (block.z == 1) {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            blur2D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage,
                    rgb_tmp_blur_edge_detect + decalage, row_stream, cols);
            edge_detect2D<<< grid, block, shared, streams[i] >>>(rgb_tmp_blur_edge_detect + decalage,
                    rgb_out_blur_edge_detect + decalage, row_stream, cols);
        }
    } else {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            blur3D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage,
                    rgb_tmp_blur_edge_detect + decalage, row_stream, cols);
            edge_detect3D<<< grid, block, shared, streams[i] >>>(rgb_tmp_blur_edge_detect + decalage,
                    rgb_out_blur_edge_detect + decalage, row_stream, cols);
        }
    }

    // Fin de chrono
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    std::cout << cudaGetErrorString(cudaGetLastError()) << std::endl;
    float elapsedTime;
    cudaEventElapsedTime(&elapsedTime, start, stop);
    std::cout << "blur_edge_detect_stream_" << block.x << "-" << block.y << "-" << block.z << ": " << elapsedTime << std::endl;
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}


void main_edge_detect_blur(const dim3 grid, const dim3 block, const unsigned int shared, const cudaStream_t* streams, const unsigned char* rgb_in,
                           unsigned char* rgb_tmp_blur_edge_detect, unsigned char* rgb_out_blur_edge_detect, int rows, int cols) {
    // Debut de chrono
    cudaEvent_t start;
    cudaEvent_t stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    // Appel kernel
    if (block.z == 1) {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            edge_detect2D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage,
                                                     rgb_tmp_blur_edge_detect + decalage, row_stream, cols);
            blur2D<<< grid, block, shared, streams[i] >>>(rgb_tmp_blur_edge_detect + decalage,
                                                            rgb_out_blur_edge_detect + decalage, row_stream, cols);
        }
    } else {
        for (std::size_t i = 0; i < taille_stream; ++i) {
            int row_stream = (int) (rows / taille_stream) + ((i == 0 || i == taille_stream - 1) ? 1 : 2);
            std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
            edge_detect3D<<< grid, block, shared, streams[i] >>>(rgb_in + decalage,
                                                     rgb_tmp_blur_edge_detect + decalage, row_stream, cols);
            blur3D<<< grid, block, shared, streams[i] >>>(rgb_tmp_blur_edge_detect + decalage,
                                                            rgb_out_blur_edge_detect + decalage, row_stream, cols);
        }
    }

    // Fin de chrono
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    std::cout << cudaGetErrorString(cudaGetLastError()) << std::endl;
    float elapsedTime;
    cudaEventElapsedTime(&elapsedTime, start, stop);
    std::cout << "edge_detect_blur_stream_" << block.x << "-" << block.y << "-" << block.z << ": " << elapsedTime << std::endl;
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}


int main(int argc, char *argv[])
{
    // Declarations
    cudaError_t err;

    std::string filename = std::string(argv[1]) + std::string(".") + std::string(argv[2]);
    std::string out(argv[1]);
    if (out == "in") {
        out = std::string("out");
    }

    cv::Mat m_in = cv::imread("in.jpg", cv::IMREAD_UNCHANGED);
    unsigned char* rgb = m_in.data;
    int rows = m_in.rows;
    int cols = m_in.cols;

    taille_rgb = 3 * rows * cols;

    std::vector<unsigned char> g_blur(taille_rgb);

    std::vector<unsigned char> g_sharpen(taille_rgb);
    std::vector<unsigned char> g_edge_detect(taille_rgb);

    std::vector<unsigned char> g_blur_edge_detect(taille_rgb);
    std::vector<unsigned char> g_edge_detect_blur(taille_rgb);

    cv::Mat m_out_blur(rows, cols, CV_8UC3, g_blur.data());

    cv::Mat m_out_sharpen(rows, cols, CV_8UC3, g_sharpen.data());
    cv::Mat m_out_edge_detect(rows, cols, CV_8UC3, g_edge_detect.data());

    cv::Mat m_out_blur_edge_detect(rows, cols, CV_8UC3, g_blur_edge_detect.data());
    cv::Mat m_out_edge_detect_blur(rows, cols, CV_8UC3, g_edge_detect_blur.data());

    unsigned char* rgb_in = nullptr;

    unsigned char* rgb_out_blur = nullptr;
    unsigned char* rgb_out_sharpen = nullptr;
    unsigned char* rgb_out_edge_detect = nullptr;

    unsigned char* rgb_tmp_blur_edge_detect = nullptr;
    unsigned char* rgb_tmp_edge_detect_blur = nullptr;
    unsigned char* rgb_out_blur_edge_detect = nullptr;
    unsigned char* rgb_out_edge_detect_blur = nullptr;

    // Init donnes kernel
    err = cudaMalloc(&rgb_in, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    err = cudaMalloc(&rgb_out_blur, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMalloc(&rgb_out_sharpen, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMalloc(&rgb_out_edge_detect, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    err = cudaMalloc(&rgb_tmp_blur_edge_detect, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMalloc(&rgb_tmp_edge_detect_blur, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMalloc(&rgb_out_blur_edge_detect, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMalloc(&rgb_out_edge_detect_blur, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    cudaStream_t streams[taille_stream];
    for (std::size_t i = 0; i < taille_stream; ++i) {
        cudaStreamCreate(&streams[i]);
    }

    one_line_rgb = 3 * cols;

    for (std::size_t i = 0; i < taille_stream; ++i) {
        std::size_t decalage = i * taille_rgb / taille_stream - (i == 0 ? 0 : one_line_rgb);
        std::size_t count = taille_rgb / taille_stream + ((i == 0 || i == taille_stream - 1) ? one_line_rgb : 2 * one_line_rgb);
        err = cudaMemcpyAsync(rgb_in + decalage,rgb + decalage, count, cudaMemcpyHostToDevice, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    }

    /////////////////////////////////////////////////////////////////
    ///////////////////// block 32 32 ///////////////////////////////
    /////////////////////////////////////////////////////////////////

    dim3 block_32_32(32, 32 / taille_stream); //nb de thread par bloc, max 1024
    dim3 grid_32_32(((cols - 1) / block_32_32.x + 1), (((rows + (taille_stream - 1) * 2) / taille_stream - 1) / block_32_32.y + 1)); // nb de block
    unsigned int shared = 3 * block_32_32.x * block_32_32.y;

    // Execution
    main_blur(grid_32_32, block_32_32, shared, streams, rgb_in, rgb_out_blur, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    main_sharpen(grid_32_32, block_32_32, shared, streams, rgb_in, rgb_out_sharpen, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    main_edge_detect(grid_32_32, block_32_32, shared, streams, rgb_in, rgb_out_edge_detect, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    main_blur_edge_detect(grid_32_32, block_32_32, shared, streams, rgb_in, rgb_tmp_blur_edge_detect, rgb_out_blur_edge_detect, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    main_edge_detect_blur(grid_32_32, block_32_32, shared, streams, rgb_in, rgb_tmp_edge_detect_blur, rgb_out_edge_detect_blur, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    // Recup donnees kernel
    for (std::size_t i = 0; i < taille_stream; ++i) {
        err = cudaMemcpyAsync(g_blur.data() + i * taille_rgb / taille_stream,
                              rgb_out_blur + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                              cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
        err = cudaMemcpyAsync(g_sharpen.data() + i * taille_rgb / taille_stream,
                              rgb_out_sharpen + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                              cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
        err = cudaMemcpyAsync(g_edge_detect.data() + i * taille_rgb / taille_stream,
                              rgb_out_edge_detect + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                              cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

        err = cudaMemcpyAsync(g_blur_edge_detect.data() + i * taille_rgb / taille_stream,
                rgb_out_blur_edge_detect + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
        err = cudaMemcpyAsync(g_edge_detect_blur.data() + i * taille_rgb / taille_stream,
                rgb_out_edge_detect_blur + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    }

    cudaDeviceSynchronize();

    cv::imwrite(out + std::string("_shared_stream_block_32-32_blur.") + std::string(argv[2]), m_out_blur);
    cv::imwrite(out + std::string("_shared_stream_block_32-32_sharpen.") + std::string(argv[2]), m_out_sharpen);
    cv::imwrite(out + std::string("_shared_stream_block_32-32_edge_detect.") + std::string(argv[2]), m_out_edge_detect);

    cv::imwrite(out + std::string("_shared_stream_block_32-32_blur_edge_detect.") + std::string(argv[2]), m_out_blur_edge_detect);
    cv::imwrite(out + std::string("_shared_stream_block_32-32_edge_detect_blur.") + std::string(argv[2]), m_out_edge_detect_blur);

    /////////////////////////////////////////////////////////////////
    ///////////////////// block 17 20 3 /////////////////////////////
    /////////////////////////////////////////////////////////////////

    dim3 block_17_20_3(17, 20 / taille_stream, 3); //nb de thread par bloc, max 1024
    dim3 grid_17_20_3(((cols - 1) / block_17_20_3.x + 1),
            (((rows + (taille_stream - 1) * 2) / taille_stream - 1) / block_17_20_3.y + 1)); // nb de block
    shared = 3 * block_17_20_3.x * block_17_20_3.y;

    // Execution
    main_blur(grid_17_20_3, block_17_20_3, shared, streams, rgb_in, rgb_out_blur, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    main_sharpen(grid_17_20_3, block_17_20_3, shared, streams, rgb_in, rgb_out_sharpen, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    main_edge_detect(grid_17_20_3, block_17_20_3, shared, streams, rgb_in, rgb_out_edge_detect, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    main_blur_edge_detect(grid_17_20_3, block_17_20_3, shared, streams, rgb_in, rgb_tmp_blur_edge_detect, rgb_out_blur_edge_detect, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    main_edge_detect_blur(grid_17_20_3, block_17_20_3, shared, streams, rgb_in, rgb_tmp_edge_detect_blur, rgb_out_edge_detect_blur, rows, cols);
    err = cudaGetLastError();
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    // Recup donnees kernel
    for (std::size_t i = 0; i < taille_stream; ++i) {
        err = cudaMemcpyAsync(g_blur.data() + i * taille_rgb / taille_stream,
                              rgb_out_blur + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                              cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
        err = cudaMemcpyAsync(g_sharpen.data() + i * taille_rgb / taille_stream,
                              rgb_out_sharpen + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                              cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
        err = cudaMemcpyAsync(g_edge_detect.data() + i * taille_rgb / taille_stream,
                              rgb_out_edge_detect + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                              cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

        err = cudaMemcpyAsync(g_blur_edge_detect.data() + i * taille_rgb / taille_stream,
                              rgb_out_blur_edge_detect + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                              cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
        err = cudaMemcpyAsync(g_edge_detect_blur.data() + i * taille_rgb / taille_stream,
                              rgb_out_edge_detect_blur + i * taille_rgb / taille_stream, taille_rgb / taille_stream,
                              cudaMemcpyDeviceToHost, streams[i]);
        if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    }

    cudaDeviceSynchronize();

    cv::imwrite(out + std::string("_shared_stream_block_17-20-3_blur.") + std::string(argv[2]), m_out_blur);
    cv::imwrite(out + std::string("_shared_stream_block_17-20-3_sharpen.") + std::string(argv[2]), m_out_sharpen);
    cv::imwrite(out + std::string("_shared_stream_block_17-20-3_edge_detect.") + std::string(argv[2]), m_out_edge_detect);

    cv::imwrite(out + std::string("_shared_stream_block_17-20-3_blur_edge_detect.") + std::string(argv[2]), m_out_blur_edge_detect);
    cv::imwrite(out + std::string("_shared_stream_block_17-20-3_edge_detect_blur.") + std::string(argv[2]), m_out_edge_detect_blur);

    /////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////

    // Nettoyage memoire
    for (std::size_t i = 0; i < taille_stream; ++i ) {
        cudaStreamDestroy(streams[i]);
    }

    cudaFree(rgb_in);

    cudaFree(rgb_out_blur);
    cudaFree(rgb_out_sharpen);
    cudaFree(rgb_out_edge_detect);

    return 0;
}
