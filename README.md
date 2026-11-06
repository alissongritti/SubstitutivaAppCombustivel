# Controle de Gastos com Combustível

Aplicativo móvel desenvolvido em **Flutter** para gerenciamento de abastecimentos de veículos, acompanhamento de gastos e monitoramento da evolução do consumo ao longo do tempo.

Atividade desenvolvida para a disciplina **Programação para Dispositivos Móveis II** da **FATEC**.

---

## 📱 Funcionalidades

1. **Cadastro e Gerenciamento de Veículo Único:**
   - Permite o cadastro de apenas **um veículo por vez**.
   - Campos: **Marca**, **Modelo**, **Ano** e **Cilindrada do motor**.
   - Integração com a **BrasilAPI (Tabela FIPE)** para busca dinâmica de marcas e filtragem dos modelos em tempo real.
   - Opção de exclusão do veículo com diálogo de confirmação (`AlertDialog`), removendo em cascata todos os abastecimentos associados para possibilitar o cadastro de um novo veículo.

2. **Registro de Abastecimentos:**
   - Seleção do tipo de combustível: **Etanol**, **Gasolina** ou **Diesel**.
   - Entrada de **preço por litro (R$)**, **quantidade de litros** e **quilometragem (KM)** no momento do abastecimento.
   - Seleção de **data e horário**.
   - Cálculo automático do valor total: $\text{Valor Total} = \text{Preço por Litro} \times \text{Quantidade de Litros}$.
   - Validações de consistência de campos e quilometragem.

3. **Dashboard e Gráficos de Desempenho:**
   - **1º Abastecimento:** Utilizado como ponto de partida (referência inicial), sem cálculos de consumo prévio.
   - **A partir do 2º Abastecimento:**
     - **Distância percorrida:** $\text{KM atual} - \text{KM anterior}$
     - **Consumo médio (km/L):** $\frac{\text{Distância}}{\text{Litros atuais}}$
     - **Custo por quilômetro (R\$/km):** $\frac{\text{Valor Total atual}}{\text{Distância}}$
   - Gráfico interativo com a biblioteca `fl_chart` exibindo a evolução temporal do consumo (km/L) e do custo por quilômetro (R$/km).
   - Cards de resumo com consumo médio geral e custo médio por quilômetro.
   - Histórico completo com detalhes de cada abastecimento e opção de exclusão.

4. **Persistência Local (SQLite):**
   - Dados salvos localmente no dispositivo via `sqflite`.
   - Persistência garantida após fechar e reabrir a aplicação.

---

## 🏛️ Arquitetura do Projeto

O projeto segue uma arquitetura modular por features:

```
lib/
├── main.dart                                  # Ponto de entrada (runApp)
├── app.dart                                   # Configuração do MaterialApp (Material 3)
└── features/
    └── combustivel/
        ├── models/
        │   ├── veiculo.dart                   # Modelo do Veículo com toMap/fromMap
        │   └── abastecimento.dart             # Modelo do Abastecimento e regras de cálculo
        ├── data/
        │   ├── banco_helper.dart              # Conexão SQLite Singleton (sqflite)
        │   └── repositorio.dart               # Operações de CRUD e exclusão em cascata
        ├── services/
        │   └── brasil_api_service.dart        # Requisições HTTP à BrasilAPI (FIPE)
        └── presentation/
            ├── screens/
            │   ├── tela_veiculo.dart          # Formulário FIPE e exclusão com diálogo
            │   ├── tela_abastecimento.dart    # Formulário de novo abastecimento
            │   └── tela_dashboard.dart        # Indicadores, médias e histórico
            └── widgets/
                └── grafico_consumo.dart       # Componente de gráfico com fl_chart
```

---

## 🌐 API Utilizada

- **BrasilAPI - Tabela FIPE:**
  - Consulta de marcas: `GET https://brasilapi.com.br/api/fipe/marcas/v1/carros`
  - Consulta de modelos por marca: `GET https://brasilapi.com.br/api/fipe/veiculos/v1/carros/{codigoMarca}`
  - Inclui fallback automático e dados locais de contingência para garantir funcionamento offline.

---

## 📦 Bibliotecas e Dependências

| Biblioteca                                      | Finalidade                                                |
| ----------------------------------------------- | --------------------------------------------------------- |
| [`sqflite`](https://pub.dev/packages/sqflite)   | Banco de dados relacional SQLite local no dispositivo     |
| [`path`](https://pub.dev/packages/path)         | Manipulação e junção de caminhos de arquivos para o banco |
| [`http`](https://pub.dev/packages/http)         | Requisições HTTP para consumo da BrasilAPI                |
| [`fl_chart`](https://pub.dev/packages/fl_chart) | Gráficos interativos de linha e evolução                  |
| [`intl`](https://pub.dev/packages/intl)         | Formatação de moeda brasileira (R$) e data/hora           |

---

## 🚀 Como Executar o Projeto

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão 3.x ou superior)
- Emulador Android, dispositivo físico ou navegador com suporte a Flutter.

### Passo a passo

1. Clone este repositório:

   ```bash
   git clone <URL_DO_REPOSITORIO>
   cd flutter_application_1
   ```

2. Instale as dependências:

   ```bash
   flutter pub get
   ```

3. Execute a aplicação no dispositivo/emulador conectado:
   ```bash
   flutter run
   ```

---

## 📸 Capturas de Tela

(Screenshot_20261105_215858.jpg)
(Screenshot_20261105_215906.jpg)
(Screenshot_20261105_221649.jpg)
(Screenshot_20261105_221654.jpg)
