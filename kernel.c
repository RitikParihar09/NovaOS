// kernel.c - Simple kernel for Nova OS
// Alpha Coders Team

// VGA text mode buffer address
volatile unsigned short* vga_buffer = (unsigned short*)0xB8000;
const int VGA_WIDTH = 80;
const int VGA_HEIGHT = 25;

// Colors
enum vga_color {
    BLACK,
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    BROWN,
    LIGHT_GREY,
    DARK_GREY,
    LIGHT_BLUE,
    LIGHT_GREEN,
    LIGHT_CYAN,
    LIGHT_RED,
    LIGHT_MAGENTA,
    LIGHT_BROWN,
    WHITE,
};

// Function to create a color attribute
unsigned char make_color(enum vga_color fg, enum vga_color bg) {
    return fg | (bg << 4);
}

// Function to create a VGA entry
unsigned short make_vga_entry(char c, unsigned char color) {
    unsigned short c16 = c;
    unsigned short color16 = color;
    return c16 | (color16 << 8);
}

// Clear the screen
void clear_screen() {
    unsigned char color = make_color(WHITE, BLACK);

    for (int y = 0; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            const int index = y * VGA_WIDTH + x;
            vga_buffer[index] = make_vga_entry(' ', color);
        }
    }
}

// Print a string at a specific position
void print_at(const char* str, int x, int y, unsigned char color) {
    int index = y * VGA_WIDTH + x;

    while (*str) {
        vga_buffer[index++] = make_vga_entry(*str++, color);
    }
}

// Kernel entry point
void kernel_main() {
    // Clear the screen
    clear_screen();

    // Print welcome messages
    print_at("Nova OS Kernel v1.0", 25, 5, make_color(LIGHT_GREEN, BLACK));
    print_at("Kernel successfully loaded!", 25, 7, make_color(WHITE, BLACK));
    print_at("Welcome to Nova OS!", 25, 9, make_color(LIGHT_CYAN, BLACK));

    // Halt the CPU
    while(1) {
        // Infinite loop to halt the CPU
    }
}