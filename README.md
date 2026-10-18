# CoProcessador Gráfico Programável

## Sumário
- [Fundamentação Teórica]()
- [Manual do Sistema](#manual-do-sistema)
- [Manual de Uso](#manual-de-uso)
- [Conclusão](#conclusão)
- [Referências](#referencias)


# Manual do Sistema

O seguinte projeto marca a segunda fase de um problema, que tem como propósito a construção de um coprocessador programável, controlado por instruções de 32 bits enviadas pelo HPS (Hard Processor System) através de uma ISA e uma Unidade de Controle, além do desenvolvimento de um driver e uma aplicação teste em C, deixando a base pronta para a integração com o jogo na fase final.

## Requisitos do Problema

O desenvolvimento do coprocessador gráfico para a fase 2 exigiu a mudança do núcleo gráfico existente anteriormente para um coprocessador programável controlado por software, eliminando o controle manual dos módulos. A arquitetura precisa incorporar uma Unidade de Busca de Instruções, Unidade de Controle, Datapath, Registrador de Instruções (IR), banco de registradores e uma Unidade Lógica e Aritmética (ULA), e os motores de background, sprites e polígonos da fase anterior passam a operar como unidades funcionais integradas neste datapath.

A partir disso, o funcionamento do sistema passa a ser ditado pelo ciclo de busca e execução de uma Instruction Set Architecture (ISA) de 32 bits, definida pela equipe, sendo que qualquer operação gráfica exibida deve resultar da execução de uma instrução dessa mesma ISA. O fornecimento de instruções pode ser feito de forma ativa, lendo ficheiros executáveis (como .mif ou .hex) a partir de uma memória interna, ou de forma passiva, recebendo uma fila de comandos do processador ARM via MMIO através de um driver escrito na linguagem de montagem Assembly ARM. Porém, em ambos os casos, é necessária a criação de um programa de demonstração em Assembly que valide a funcionalidade da ISA.

A geração da imagem da saída VGA deve ser estável, a partir da resolução lógica 320X240, e operar de forma independente da execução de instruções pela Unidade de Controle, sendo necessária a inclusão de uma Unidade de Controle de Quadro, um Compositor, uma Controladora VGA.

## Arquitetura e Fluxo de Dados

# Manual de Uso

## Requisitos:

- Placa DE1-SoC com Linux no HPS e acesso por terminal;
- Monitor e cabo VGA conectados à placa;
- Computador com o software Quartus Prime instalado para compilar e programar a FPGA;

## Instalação e configuração:

- Faça o download de todo o conteúdo do repositório;
- No Quartus Prime, abra o projeto com o arquivo `soc_system.qsf` e defina DE1_SOC_golden_top.v como top-level;
- Caso faça alguma alteração no código e deseje recompilar, utilize a ferramenta Compile Design no Quartus.

## Programação na placa:

- Conecte a placa DE1-SoC no computador via USB e conecte o monitor VGA à placa;
- No Quartus Prime, abra a ferramenta Programmer, clique em Add File, vá até a pasta do projeto e selecione arquivo compilado `soc_system.sof`;
- Verifique se a placa foi reconhecida no Hardware Setup e clique em Start para transferir o código para a placa.

## Uso:

- Abra a pasta onde os arquivos foram compilados;
- Abra o terminal dentro da pasta;
- Use os seguintes comandos no terminal:
```
cd /home/root
```
```
gcc -o aplicacao aplicacao.c driver.S
```
- Em seguida, execute através do comando:
```
sudo ./aplicacao
```
- Para usar o menu, digite o número da opção e pressione a tecla Enter. A aplicação pede cada campo da instrução, mostrando a faixa de valores válida entre os colchetes. Valores inválidos ou fora da faixa são recusados e o campo é solicitado novamente.

| Opção | Instrução | Faixa |
|:--------------:|:----:|:------:|
| 1 | Reset | nenhum |
| 2 | Set sprite info | camada [0-63], id [0-63], x [0-511], y [0-255] |
| 3 | Set sprite config | camada [0-63], visivel [0-1], flipx [0-1], flipy [0-1] |
| 4 | Set pol info | camada [0-3], vertice [0-3], x [0-511], y [0-255]  |
| 5 | Set pol config | camada [0-3], visivel [0-1], trapezio [0-1], cor [0-255]  |
| 6 | Set background info | funcao [0-1], roll [0-3], x [0-63], y [0-31], cor [0-255]  |
| 7 | Toggle layer | layer [0-1] |
| 8 | Ler PIOs | nenhum (mostra `PIO_READY` e `PIO_VALID`) |
| 9 | Sequência de teste completa | nenhum |
| 0 | Sair | nenhum |

Exemplo: colocar um sprite na tela

```
Opcao: 2
  camada [0-63]: 1
  id [0-63]: 5
  x [0-511]: 200
  y [0-255]: 200

Opcao: 3
  camada [0-63]: 1
  visivel [0-1]: 1
  flipx [0-1]: 0
  flipy [0-1]: 0
```

A instrução de info define a posição e o padrão; a de config torna o sprite visível. Para movê-lo depois, é necessário repetir a opção 2 com novas coordenadas, sem reenviar a opção 3.

Exemplo: desenhar um polígono

1. Opção 4, quatro vezes, com `vertice` de 0 a 3 e as coordenadas de cada vértice (a mesma camada nas quatro).
2. Opção 5 com a mesma camada, `visivel` = 1, o formato em trapezio e a cor (1 a 255; a cor 0 é transparente).

A opção 9 executa uma cena de demonstração completa (sprite, background, polígono e ordem de camadas). Rode ela primeiro para verificar se o sistema está funcionando.

# Conclusão

É possível concluir que os requisitos funcionais propostos para a segunda fase foram cumpridos com sucesso, visto que o sistema evoluiu de um conjunto de motores de desenho (sprites, polígonos e background) controlados manualmente por chaves e botões para um coprocessador programável, operando com uma ISA de 32 bits, com Unidade de Controlo, uso do protocolo de handshake e um driver em Assembly ARM acessado por uma aplicação em C, deixando o sistema preparado para a integração final com o jogo na fase 3. Além disso, o problema de sincronização visual apresentado no problema anterior foi solucionado, garantindo uma geração de imagem estável, outro requisito presente na fase 2. 

# Referências

Manual da placa (DE1-SoC) e do dispositivo Cyclone V pode ser consultados na página de [Recursos do LTEC3 - LEDS] https://sites.google.com/uefs.br/ltec3-leds/recursos

