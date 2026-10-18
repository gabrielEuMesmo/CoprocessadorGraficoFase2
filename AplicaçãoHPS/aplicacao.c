#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include "hps_0.h"

#define HW_REGS_SPAN 0x00200000
#define HW_REGS_MASK (HW_REGS_SPAN - 1)

extern void *abrir_memoria(void);
extern void fechar_memoria(void);

extern void enviar_reset(void);
extern void enviar_sprite_info(uint32_t camada, uint32_t id, uint32_t x, uint32_t y);
extern void enviar_sprite_config(uint32_t camada, uint32_t visivel, uint32_t flipx, uint32_t flipy);
extern void enviar_pol_info(uint32_t camada, uint32_t vertice, uint32_t x, uint32_t y);
extern void enviar_pol_config(uint32_t camada, uint32_t visivel, uint32_t trapezio, uint32_t cor);
extern void enviar_bg_info(uint32_t funcao, uint32_t roll, uint32_t x, uint32_t y, uint32_t cor);
extern void enviar_toggle_layer(uint32_t layer);

static volatile uint32_t *pio_ready;
static volatile uint32_t *pio_valid;
static volatile uint32_t *pio_ativa;
static volatile uint32_t *pio_clear;

/* Le um numero do teclado e valida a faixa [0, max]. */
static uint32_t ler_campo(const char *nome, uint32_t max) {
    char buf[64];
    char *fim;
    unsigned long v;

    for (;;) {
        printf("  %s [0-%u]: ", nome, max);
        fflush(stdout);

        if (!fgets(buf, sizeof(buf), stdin)) {
            printf("\nEntrada encerrada. Saindo...\n");
            fechar_memoria();
            exit(0);
        }

        v = strtoul(buf, &fim, 0);   /* aceita decimal, 0x.. hex */
        if (fim == buf || (*fim != '\n' && *fim != '\0')) {
            printf("  Valor invalido.\n");
            continue;
        }
        if (v > max) {
            printf("  Fora da faixa (maximo %u).\n", max);
            continue;
        }
        return (uint32_t)v;
    }
}

static void mostrar_menu(void) {
    printf("\n================ MENU ================\n");
    printf(" 1 - Reset\n");
    printf(" 2 - Set sprite info\n");
    printf(" 3 - Set sprite config\n");
    printf(" 4 - Set pol info\n");
    printf(" 5 - Set pol config\n");
    printf(" 6 - Set background info\n");
    printf(" 7 - Toggle layer\n");
    printf(" 8 - Ler PIOs (ready / valid)\n");
    printf(" 9 - Sequencia de teste completa\n");
    printf(" 0 - Sair\n");
    printf("======================================\n");
}

static void op_sprite_info(void) {
    uint32_t camada = ler_campo("camada", 0x3F);
    uint32_t id     = ler_campo("id",     0x3F);
    uint32_t x      = ler_campo("x",      0x1FF);
    uint32_t y      = ler_campo("y",      0xFF);
    enviar_sprite_info(camada, id, x, y);
}

static void op_sprite_config(void) {
    uint32_t camada  = ler_campo("camada",  0x3F);
    uint32_t visivel = ler_campo("visivel", 1);
    uint32_t flipx   = ler_campo("flipx",   1);
    uint32_t flipy   = ler_campo("flipy",   1);
    enviar_sprite_config(camada, visivel, flipx, flipy);
}

static void op_pol_info(void) {
    uint32_t camada  = ler_campo("camada",  0x3);
    uint32_t vertice = ler_campo("vertice", 0x3);
    uint32_t x       = ler_campo("x",       0x1FF);
    uint32_t y       = ler_campo("y",       0xFF);
    enviar_pol_info(camada, vertice, x, y);
}

static void op_pol_config(void) {
    uint32_t camada   = ler_campo("camada",   0x3);
    uint32_t visivel  = ler_campo("visivel",  1);
    uint32_t trapezio = ler_campo("trapezio", 1);
    uint32_t cor      = ler_campo("cor",      0xFF);
    enviar_pol_config(camada, visivel, trapezio, cor);
}

static void op_bg_info(void) {
    uint32_t funcao = ler_campo("funcao", 1);
    uint32_t roll   = ler_campo("roll",   0x3);
    uint32_t x      = ler_campo("x",      0x3F);
    uint32_t y      = ler_campo("y",      0x1F);
    uint32_t cor    = ler_campo("cor",    0xFF);
    enviar_bg_info(funcao, roll, x, y, cor);
}

static void op_toggle_layer(void) {
    uint32_t layer = ler_campo("layer", 1);
    enviar_toggle_layer(layer);
}

static void op_ler_pios(void) {
    printf("  PIO_READY = %u\n", *pio_ready);
    printf("  PIO_VALID = %u\n", *pio_valid);
}

static void op_sequencia_completa(void) {
    printf("  Executando sequencia completa...\n");

    enviar_reset();
    usleep(100000);

    enviar_sprite_info(1, 5, 200, 200);
    enviar_sprite_config(1, 1, 0, 1);
    enviar_bg_info(0, 2, 10, 20, 255);

    enviar_pol_info(0, 0, 0, 0);
    enviar_pol_info(0, 1, 100, 0);
    enviar_pol_info(0, 2, 100, 100);
    enviar_pol_info(0, 3, 0, 100);
    enviar_pol_config(0, 1, 0, 200);

    enviar_toggle_layer(1);

    printf("  Sequencia concluida.\n");
}

int main(void) {
    void *virtual_base = abrir_memoria();

    if (virtual_base == (void *)-1 || virtual_base == NULL) {
        printf("ERRO: Falha ao abrir /dev/mem. Rode com 'sudo'.\n");
        return 1;
    }

    uint8_t *base = (uint8_t *)virtual_base;
    pio_ready = (volatile uint32_t *)(base + (PIO_READY_BASE & HW_REGS_MASK));
    pio_valid = (volatile uint32_t *)(base + (PIO_VALID_BASE & HW_REGS_MASK));
    pio_ativa = (volatile uint32_t *)(base + (PIO_ATIVA_BASE & HW_REGS_MASK));
    pio_clear = (volatile uint32_t *)(base + (PIO_CLEAR_BASE & HW_REGS_MASK));

    /* Estado inicial dos sinais de controle */
    *pio_ativa = 0;
    *pio_clear = 0;

    int opcao = -1;
    char buf[32];

    while (opcao != 0) {
        mostrar_menu();
        printf("Opcao: ");
        fflush(stdout);

        if (!fgets(buf, sizeof(buf), stdin)) break;
        opcao = atoi(buf);

        switch (opcao) {
            case 1:
                enviar_reset();
                break;
            case 2: op_sprite_info();          break;
            case 3: op_sprite_config();        break;
            case 4: op_pol_info();             break;
            case 5: op_pol_config();           break;
            case 6: op_bg_info();              break;
            case 7: op_toggle_layer();         break;
            case 8: op_ler_pios();             break;
            case 9: op_sequencia_completa();   break;
            case 0: printf("Saindo...\n");     break;
            default: printf("Opcao invalida.\n"); break;
        }
    }

    fechar_memoria();
    return 0;
}