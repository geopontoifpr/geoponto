# 🕐 GeoPonto

Aplicativo móvel de controle de ponto eletrônico e gestão de jornada de trabalho para pequenas e médias empresas, com validação por geolocalização, autenticação biométrica e emissão de espelho de ponto em PDF.

![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-BaaS-3ECF8E?logo=supabase)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql)
![Android](https://img.shields.io/badge/Android-8.0+-3DDC84?logo=android)

---

## 📑 Sumário

1. [Sobre o Projeto](#-sobre-o-projeto)
2. [Objetivos](#-objetivos)
3. [Download Rápido (APK) e Credenciais para a Banca](#-download-rápido-apk-e-credenciais-para-a-banca)
4. [Perfis de Usuário](#-perfis-de-usuário)
5. [Funcionalidades Principais](#-funcionalidades-principais)
6. [Arquitetura e Segurança](#-arquitetura-e-segurança)
7. [Tecnologias Utilizadas](#-tecnologias-utilizadas)
8. [Estrutura de Diretórios](#-estrutura-de-diretórios)
9. [Guia de Instalação e Execução na IDE (Desenvolvedores)](#️-guia-de-instalação-e-execução-na-ide-desenvolvedores)
10. [Equipe e Instituição](#-equipe-e-instituição)

---

## 📋 Sobre o Projeto

O **GeoPonto** é um sistema de Registro Eletrônico de Ponto via Programa (**REP-P**) desenvolvido como Projeto Integrador do curso de **Tecnologia em Análise e Desenvolvimento de Sistemas** do **Instituto Federal do Paraná (IFPR) — Campus Foz do Iguaçu**.

A solução substitui registradores físicos de alto custo (REP-C) por uma aplicação móvel moderna inspirada nas diretrizes da **Portaria MTP nº 671/2021**, oferecendo:

- 📍 **Validação por Geolocalização:** O registro de ponto é validado por GPS dentro do raio geográfico (em metros) configurado pela sede da empresa, contando com proteção contra localização simulada (*Fake GPS*).
- 🔒 **Autenticação Biométrica:** Confirmação da identidade do colaborador por meio do sensor biométrico nativo do dispositivo Android antes de efetivar cada batida.
- 📊 **Cálculo Automático de Jornada:** Apuração automática de horas previstas, trabalhadas, abonadas, créditos e débitos mensais, respeitando feriados e histórico de vigência de jornadas.
- ✅ **Fluxo de Ocorrências e Fechamento:** Tratativa de justificativas e pedidos de abono sem adulterar os registros originais de ponto, seguida pela consolidação mensal da folha e exportação em PDF.

---

## 🎯 Objetivos

- Desenvolver um aplicativo móvel intuitivo para marcação de entradas, intervalos e saídas da jornada de trabalho;
- Permitir o controle de horários, validação geográfica dos registros e acompanhamento gerencial por setor;
- Reduzir retrabalhos manuais de RH e automatizar o cálculo do saldo mensal de horas.

---

## 📲 Download Rápido (APK) e Credenciais para a Banca

Para avaliar o aplicativo diretamente em um dispositivo **Android (8.0 ou superior)** sem necessidade de compilar o código:

1. Acesse a seção de [**Releases do Repositório**](https://github.com/geopontoifpr/geoponto/releases);
2. Baixe o arquivo instalável **`.apk`** da versão mais recente com apenas um clique;
3. Instale e abra o aplicativo no seu smartphone Android.

### 🔑 Credenciais de Teste Provisionadas

Como o sistema exige autenticação, disponibilizamos três contas pré-configuradas para que a banca avaliadora possa testar cada nível de permissão:

| Perfil de Acesso | E-mail Corporativo | Senha | O que testar neste perfil |
| :--- | :--- | :--- | :--- |
| **Administrador** | `adm@geoponto.com` | `123456` | Configuração dos dados/coordenadas da empresa, gestão de setores e cadastro geral de gestores e funcionários. |
| **Gestor** | `gestor@geoponto.com` | `234567` | Registro do próprio ponto, gestão de colaboradores do setor, avaliação de ocorrências (aceitar/recusar) e fechamento mensal de folha. |
| **Colaborador** | `maria@geoponto.com` | `234567` | Registro de ponto (GPS + biometria), consulta do calendário mensal, abertura de ocorrências e impressão do espelho de ponto em PDF. |

---

## 👥 Perfis de Usuário

O sistema opera em uma interface unificada que adapta suas abas e permissões conforme o perfil do usuário autenticado:

| Perfil | Descrição | Principais Permissões |
| :--- | :--- | :--- |
| `ADMINISTRADOR` | Proprietário / Responsável geral pela empresa | Cadastra e edita dados da empresa e raio de GPS; gerencia setores; cadastra gestores, funcionários e vínculos de jornada. |
| `GESTOR` | Responsável imediato por um setor específico | Registra ponto; cadastra e gerencia funcionários do seu setor; aprova ou recusa ocorrências; consolida e fecha a folha mensal da equipe. |
| `FUNCIONARIO` | Colaborador vinculado a um setor | Registra ponto diário; consulta histórico e saldo mensal; solicita abonos/correções por meio de ocorrências; emite espelho de ponto em PDF. |

---

## 📱 Funcionalidades Principais

- ✅ **Autenticação e Primeiro Acesso (`RF03` / `RF16`):** Login por e-mail e senha com fluxo obrigatório de troca de senha no primeiro acesso.
- ✅ **Configuração da Empresa e Setores (`RF02` / `RF15`):** Cadastro de razão social, CNPJ, coordenadas geográficas (latitude/longitude), raio permitido e CRUD completo de setores.
- ✅ **Gestão de Equipe e Vigência de Jornadas (`RF01` / `RF09` / `RF14`):** Cadastro de gestores e colaboradores com atribuição de carga horária semanal (30h, 40h, 44h) preservando o histórico de vigência sem afetar meses anteriores.
- ✅ **Registro de Ponto Seguro (`RF04`):** Validação de distância via GPS + leitura biométrica, respeitando a sequência estrita de batidas (`Entrada 1` ➔ `Saída 1` ➔ `Entrada 2` ➔ `Saída 2`).
- ✅ **Calendário e Extrato Mensal (`RF05` / `RF06`):** Visualização interativa por cores de status no calendário, cálculo automático de feriados e geração de relatório mensal em **PDF**.
- ✅ **Gestão de Ocorrências (`RF07` / `RF10`):** Solicitação de abono pelo colaborador (respeitando o limite de 72h e 1 ocorrência por dia) e avaliação com parecer do gestor.
- ✅ **Fechamento Mensal (`RF11`):** Consolidação do saldo do mês na tabela `fechamentos_mensais`, bloqueando alterações e novas ocorrências no período fechado.

---

## 🏗️ Arquitetura e Segurança

O projeto adota uma arquitetura em camadas no cliente móvel (**Screen ➔ Controller ➔ Service ➔ Repository ➔ Model**) integrada ao **Supabase (BaaS)**:

```text
Flutter App (Android)
       │
       │  Supabase SDK (HTTPS)
       ▼
┌──────────────────────┐
│    Supabase Auth     │ ──── auth.users (Autenticação e Hash de Senha)
└──────────────────────┘
       │
       │  Token JWT
       ▼
┌──────────────────────┐
│    PostgreSQL 15     │
│  + Políticas de RLS  │ ──── Funções RPC (SECURITY DEFINER)
└──────────────────────┘
       │
       └──── Schema public
               ├── empresas
               ├── setores
               ├── usuarios
               ├── jornadas_trabalho
               ├── jornadas_usuarios
               ├── registros_ponto
               ├── ocorrencias
               └── fechamentos_mensais
```

### 🔐 Princípios de Segurança

- **Autenticação:** Gerenciada nativamente pelo *Supabase Auth* (`auth.users`), garantindo que nenhuma senha em texto puro transite ou seja armazenada nas tabelas públicas.
- **Row Level Security (RLS):** Todas as tabelas possuem políticas de segurança em nível de linha ativadas no PostgreSQL, restringindo leituras e escritas com base no `auth.uid()` e no cargo do usuário.
- **Variáveis de Ambiente:** As credenciais de conexão com o banco são injetadas via arquivo `.env` (`flutter_dotenv`), evitando a exposição de chaves estáticas no código-fonte.

---

## 🚀 Tecnologias Utilizadas

- **Frontend Mobile:** [Flutter](https://flutter.dev/) (SDK 3.24+) & [Dart](https://dart.dev/) (3.5+)
- **Backend & Banco de Dados:** [Supabase](https://supabase.com/) (PostgreSQL 15, GoTrue Auth, PostgREST, RPC)
- **Principais Pacotes:**
  - `supabase_flutter`: Integração com autenticação e banco de dados;
  - `geolocator`: Captura de coordenadas GPS e cálculo de distância (fórmula de Haversine);
  - `local_auth`: Integração com biometria nativa do Android;
  - `pdf` & `printing`: Geração e compartilhamento do espelho de ponto em formato A4;
  - `flutter_dotenv`: Gerenciamento de variáveis de ambiente.

---

## 📂 Estrutura de Diretórios

O código-fonte principal está organizado dentro do diretório `lib/` seguindo a divisão modular por domínio (*feature-first*):

```text
lib/
├── core/
│   ├── constants/       # Paleta de cores (AppColors) e constantes globais
│   ├── errors/          # Hierarquia de exceções customizadas (AppException)
│   ├── screens/         # Telas transversais (PainelUnificadoScreen, EquipeScreen, ExtratoMensalScreen)
│   ├── services/        # Serviços nativos e singletons (SupabaseService, LocationService, BiometriaService)
│   ├── themes/          # Temas Claro/Escuro (AppThemes e ThemeController)
│   ├── utils/           # Utilitários (FeriadosUtil, CalculadoraDistanciaUtil, SnackbarUtil)
│   └── widgets/         # Componentes visuais reutilizáveis (CustomAppBar, ActionCard, ListaExtratoDiario, etc.)
├── features/
│   ├── admin/           # Gestão de empresa e setores (Controllers, Models, Repositories, Screens, Services)
│   ├── auth/            # Login e fluxo de primeiro acesso
│   ├── colaborador/     # Registro de ponto, frequência mensal e serviço de geração de PDF
│   ├── gestor/          # Modelos e telas de fechamento mensal
│   ├── jornadas/        # Controle de jornadas semanais e histórico de vigência
│   ├── ocorrencias/     # CRUD de ocorrências do colaborador e avaliação do gestor
│   └── usuarios/        # Cadastro, edição e ativação/inativação de membros da equipe
└── main.dart            # Ponto de entrada da aplicação e inicialização de serviços
```

---

## 🛠️ Guia de Instalação e Execução na IDE (Desenvolvedores)

Caso deseje importar o código-fonte em sua máquina para análise ou execução em modo de desenvolvimento (via **VS Code** ou **Android Studio**), siga os passos abaixo:

### 1. Pré-requisitos
- **Git** instalado;
- **Flutter SDK** (versão `3.24` ou superior) e **Dart SDK** (`3.5+`) configurados no `PATH`;
- **VS Code** (com as extensões *Flutter* e *Dart*) ou **Android Studio**;
- Dispositivo físico Android (conectado via Depuração USB), Emulador Android (API 26+) ou navegador Google Chrome.

### 2. Clonar o Repositório (Branch `main`)
Abra o terminal na pasta onde deseja salvar o projeto e execute o comando abaixo para clonar diretamente a branch `main`:

```bash
git clone -b main https://github.com/geopontoifpr/geoponto.git
cd geoponto
```

### 3. Abrir o Projeto na IDE
Caso utilize o **Visual Studio Code**, execute no terminal:

```bash
code .
```
*(Ou abra a pasta `geoponto` manualmente através do menu `File > Open Folder` na sua IDE de preferência).*

### 4. Configurar as Variáveis de Ambiente (`.env`)
Na raiz do projeto (no mesmo nível do arquivo `pubspec.yaml`), crie um arquivo chamado **`.env`** contendo as seguintes credenciais de homologação do projeto no Supabase:

```env
SUPABASE_URL=https://nmwvxnioxrbdpgwnqdjx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5td3Z4bmlveHJiZHBnd25xZGp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5OTQ1OTMsImV4cCI6MjEwNDU3MDU5M30.T-03l7XaWTlpYG-9ZQ5xtPLM7PShfIwjI01ydEnIubc
```

> **Nota para a Banca Avaliadora:** As chaves públicas acima (`anon_key`, protegidas pelas políticas de *Row Level Security* do banco) foram disponibilizadas para permitir a compilação imediata do projeto em ambiente local. Caso prefira testar diretamente no smartphone sem compilar, utilize o APK disponível na aba [**Releases**](https://github.com/geopontoifpr/geoponto/releases).

### 5. Instalar as Dependências e Executar
No terminal integrado da IDE, baixe os pacotes do projeto e inicie a aplicação:

```bash
flutter clean
flutter pub get
flutter run
```

Para gerar um novo arquivo instalável (`.apk`) de produção localmente, utilize:

```bash
flutter build apk --release
```

---

## 👨‍💻 Equipe e Instituição

- **Caroline de Souza Viana** — `carolineviana2015x@gmail.com`
- **Giovaime Orso Vieira** — `giovaime@gmail.com`
- **Leonardo Nogueira Hilgenberg** — `leonhilgenberg@gmail.com`

**Instituição:** Instituto Federal do Paraná (IFPR) — Campus Foz do Iguaçu  
**Curso:** Tecnologia em Análise e Desenvolvimento de Sistemas (TADS)  
**Disciplina:** Projeto Integrador

---

## 📄 Licença

Projeto acadêmico desenvolvido exclusivamente para fins educacionais e de avaliação no Instituto Federal do Paraná (IFPR).
