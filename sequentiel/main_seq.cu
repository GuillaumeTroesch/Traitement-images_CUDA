#include <opencv2/opencv.hpp>
#include <vector>
#include <iostream>
#include <chrono>
#include <string>

void blur(const unsigned char* rgb_in, unsigned char* rgb_out_blur, int rows, int cols) {
    for (std::size_t row = 1; row < rows - 1; ++row) {
        for (std::size_t col = 1; col < cols - 1; ++col) {
            for (std::size_t rgb = 0; rgb < 3; ++rgb)
            {
                unsigned char hg = rgb_in[3 * ((row - 1) * cols + col - 1) + rgb];
                unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
                unsigned char hd = rgb_in[3 * ((row - 1) * cols + col + 1) + rgb];
                unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
                unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
                unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
                unsigned char bg = rgb_in[3 * ((row + 1) * cols + col - 1) + rgb];
                unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
                unsigned char bd = rgb_in[3 * ((row + 1) * cols + col + 1) + rgb];

                rgb_out_blur[3 * (row * cols + col) + rgb] = (hg + h + hd + g + c + d + bg + b + bd) / 9;
            }
        }
    }
}

void sharpen(const unsigned char* rgb_in, unsigned char* rgb_out_sharpen, int rows, int cols) {
    for (std::size_t row = 1; row < rows - 1; ++row) {
        for (std::size_t col = 1; col < cols - 1; ++col) {
            for (std::size_t rgb = 0; rgb < 3; ++rgb)
            {
                unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
                unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
                unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
                unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
                unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
                int somme = (-3 * (h + g + d + b) + 21 * c) / 9;

                if (somme > 255) somme = 255;
                if (somme < 0) somme = 0;

                rgb_out_sharpen[3 * (row * cols + col) + rgb] = somme;
            }
        }
    }
}

void edge_detect(const unsigned char* rgb_in, unsigned char* rgb_out_edge_detect, int rows, int cols) {
    for (std::size_t row = 1; row < rows - 1; ++row) {
        for (std::size_t col = 1; col < cols - 1; ++col) {
            for (std::size_t rgb = 0; rgb < 3; ++rgb)
            {
                unsigned char h = rgb_in[3 * ((row - 1) * cols + col) + rgb];
                unsigned char g = rgb_in[3 * (row * cols + col - 1) + rgb];
                unsigned char c = rgb_in[3 * (row * cols + col) + rgb];
                unsigned char d = rgb_in[3 * (row * cols + col + 1) + rgb];
                unsigned char b = rgb_in[3 * ((row + 1) * cols + col) + rgb];
                int somme = (9 * (h + g + d + b) - 36 * c) / 9;

                if (somme > 255) somme = 255;
                if (somme < 0) somme = 0;

                rgb_out_edge_detect[3 * (row * cols + col) + rgb] = somme;
            }
        }
    }
}


void main_blur(const unsigned char* rgb_in, unsigned char* rgb_out_blur, int rows, int cols) {
    //Debut de chrono
    std::chrono::time_point<std::chrono::system_clock> start, end;
    start = std::chrono::system_clock::now();

    blur(rgb_in, rgb_out_blur, rows, cols);

    //Fin de chrono
    end = std::chrono::system_clock::now();
    int elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
    std::cout << "blur_seq: " << elapsedTime << std::endl;
}

void main_sharpen(const unsigned char* rgb_in, unsigned char* rgb_out_sharpen, int rows, int cols)
{
    //Debut de chrono
    std::chrono::time_point<std::chrono::system_clock> start, end;
    start = std::chrono::system_clock::now();

    sharpen(rgb_in, rgb_out_sharpen, rows, cols);

    //Fin de chrono
    end = std::chrono::system_clock::now();
    int elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    std::cout << "sharpen_seq: " << elapsedTime << std::endl;
}

void main_edge_detect(const unsigned char* rgb_in, unsigned char* rgb_out_edge_detect, int rows, int cols)
{
    //Debut de chrono
    std::chrono::time_point<std::chrono::system_clock> start, end;
    start = std::chrono::system_clock::now();

    edge_detect(rgb_in, rgb_out_edge_detect, rows, cols);

    //Fin de chrono
    end = std::chrono::system_clock::now();
    int elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    std::cout << "edge_detect_seq: " << elapsedTime << std::endl;
}


void main_blur_edge_detect(const unsigned char* rgb_in, unsigned char* rgb_tmp_blur_edge_detect,
                           unsigned char* rgb_out_blur_edge_detect, int rows, int cols)
{
    //Debut de chrono
    std::chrono::time_point<std::chrono::system_clock> start, end;
    start = std::chrono::system_clock::now();

    blur(rgb_in, rgb_tmp_blur_edge_detect, rows, cols);
    edge_detect(rgb_tmp_blur_edge_detect, rgb_out_blur_edge_detect, rows, cols);

    //Fin de chrono
    end = std::chrono::system_clock::now();
    int elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    std::cout << "blur_edge_detect_seq: " << elapsedTime << std::endl;
}

void main_edge_detect_blur(const unsigned char* rgb_in, unsigned char* rgb_tmp_edge_detect_blur,
                           unsigned char* rgb_out_edge_detect_blur, int rows, int cols)
{
    //Debut de chrono
    std::chrono::time_point<std::chrono::system_clock> start, end;
    start = std::chrono::system_clock::now();

    edge_detect(rgb_in, rgb_tmp_edge_detect_blur, rows, cols);
    blur(rgb_tmp_edge_detect_blur, rgb_out_edge_detect_blur, rows, cols);

    //Fin de chrono
    end = std::chrono::system_clock::now();
    int elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    std::cout << "edge_detect_blur_seq: " << elapsedTime << std::endl;
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

    cv::Mat m_in = cv::imread(filename, cv::IMREAD_UNCHANGED);
    auto rgb = m_in.data;
    auto rows = m_in.rows;
    auto cols = m_in.cols;

    size_t taille_rgb = 3 * rows * cols;
    std::vector< unsigned char > g_blur(taille_rgb);

    std::vector< unsigned char > g_sharpen(taille_rgb);
    std::vector< unsigned char > g_edge_detect(taille_rgb);

    std::vector< unsigned char > g_blur_edge_detect(taille_rgb);
    std::vector< unsigned char > g_edge_detect_blur(taille_rgb);

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
    err = cudaMallocHost(&rgb_in, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    err = cudaMallocHost(&rgb_out_blur, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMallocHost(&rgb_out_sharpen, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMallocHost(&rgb_out_edge_detect, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    err = cudaMallocHost(&rgb_tmp_blur_edge_detect, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMallocHost(&rgb_tmp_edge_detect_blur, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMallocHost(&rgb_out_blur_edge_detect, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMallocHost(&rgb_out_edge_detect_blur, taille_rgb);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    err = cudaMemcpy(rgb_in, rgb, taille_rgb, cudaMemcpyHostToDevice);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    // Execution
    main_blur(rgb_in, rgb_out_blur, rows, cols);
    main_sharpen(rgb_in, rgb_out_sharpen, rows, cols);
    main_edge_detect(rgb_in, rgb_out_edge_detect, rows, cols);

    main_blur_edge_detect(rgb_in, rgb_tmp_blur_edge_detect, rgb_out_blur_edge_detect, rows, cols);
    main_edge_detect_blur(rgb_in, rgb_tmp_edge_detect_blur, rgb_out_edge_detect_blur, rows, cols);

    // Recup donnees kernel
    err = cudaMemcpy(g_blur.data(), rgb_out_blur, taille_rgb, cudaMemcpyDeviceToHost);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMemcpy(g_sharpen.data(), rgb_out_sharpen, taille_rgb, cudaMemcpyDeviceToHost);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMemcpy(g_edge_detect.data(), rgb_out_edge_detect, taille_rgb, cudaMemcpyDeviceToHost);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    err = cudaMemcpy(g_blur_edge_detect.data(), rgb_out_blur_edge_detect, taille_rgb, cudaMemcpyDeviceToHost);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }
    err = cudaMemcpy(g_edge_detect_blur.data(), rgb_out_edge_detect_blur, taille_rgb, cudaMemcpyDeviceToHost);
    if ( err != cudaSuccess ) { std::cerr << "Error" << std::endl; }

    cv::imwrite(out + std::string("_seq_blur.") + std::string(argv[2]), m_out_blur);
    cv::imwrite(out + std::string("_seq_sharpen.") + std::string(argv[2]), m_out_sharpen);
    cv::imwrite(out + std::string("_seq_edge_detect.") + std::string(argv[2]), m_out_edge_detect);

    cv::imwrite(out + std::string("_seq_blur_edge_detect.") + std::string(argv[2]), m_out_blur_edge_detect);
    cv::imwrite(out + std::string("_seq_edge_detect_blur.") + std::string(argv[2]), m_out_edge_detect_blur);

    // Nettoyage memoire
    cudaFreeHost(rgb_in);

    cudaFreeHost(rgb_out_blur);
    cudaFreeHost(rgb_out_sharpen);
    cudaFreeHost(rgb_out_edge_detect);

    cudaFreeHost(rgb_tmp_blur_edge_detect);
    cudaFreeHost(rgb_tmp_edge_detect_blur);
    cudaFreeHost(rgb_out_blur_edge_detect);
    cudaFreeHost(rgb_out_edge_detect_blur);
    return 0;
}