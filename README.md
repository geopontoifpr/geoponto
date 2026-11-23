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
5. [Guia de Instalação e Execução na IDE (Desenvolvedores)](#-guia-de-instalação-e-execução-na-ide-desenvolvedores)
6. [Equipe e Instituição](#-equipe-e-instituição)

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

### 🔑 Credenciais de Teste Provisionadas (APK)

Como o sistema exige autenticação, disponibilizamos três contas pré-configuradas no ambiente publicado para que a banca avaliadora possa testar cada nível de permissão:

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

## 🔧 Guia de Instalação e Execução na IDE (Desenvolvedores)

Caso deseje importar o código-fonte em sua máquina para análise ou execução em modo de desenvolvimento (via **VS Code** ou **Android Studio**) utilizando seu próprio banco de dados isolado, siga os passos abaixo:

### 1. Pré-requisitos
- **Git** instalado;
- **Flutter SDK** (versão `3.24` ou superior) e **Dart SDK** (`3.5+`) configurados no `PATH`;
- **VS Code** (com as extensões *Flutter* e *Dart*) ou **Android Studio**;
- Conta gratuita no [Supabase](https://supabase.com/);
- Dispositivo físico Android (conectado via Depuração USB), Emulador Android (API 26+) ou navegador Google Chrome.

### 2. Clonar o Repositório (Branch `main`)
Abra o terminal na pasta onde deseja salvar o projeto e execute o comando abaixo para clonar diretamente a branch `main`:

```bash
git clone -b main [https://github.com/geopontoifpr/geoponto.git](https://github.com/geopontoifpr/geoponto.git)
cd geoponto
```

### 3. Abrir o Projeto na IDE
Caso utilize o **Visual Studio Code**, execute no terminal:

```bash
code .
```
*(Ou abra a pasta `geoponto` manualmente através do menu `File > Open Folder` na sua IDE de preferência).*

### 4. Configurar o Banco de Dados (Supabase)
1. Acesse [supabase.com](https://supabase.com/), faça login e clique em **New Project** para criar um novo banco PostgreSQL;
2. No menu lateral esquerdo do projeto criado, abra o **SQL Editor**, clique em **New query**, copie todo o conteúdo do arquivo [`supabase/setup.sql`](supabase/setup.sql) deste repositório e clique em **Run** — isso criará automaticamente os tipos `ENUM`, todas as tabelas, funções RPC, políticas de segurança (RLS) e as jornadas padrão (`30h`, `40h` e `44h`);
3. **Criar o primeiro usuário Administrador:**
   - No menu lateral do Supabase, acesse **Authentication > Users** e clique em **Add user > Create new user** (informe um e-mail, uma senha e marque **Auto Confirm User**);
   - Copie o **User UID** gerado e execute o comando abaixo no **SQL Editor** (substituindo o UUID e os dados pelos do usuário criado):

```sql
INSERT INTO public.usuarios (id, nome, email, tipo_usuario, ativo, primeiro_acesso)
VALUES (
  'COLE-AQUI-O-UUID-DO-AUTH',
  'Administrador',
  'admin@empresa.com',
  'ADMINISTRADOR',
  true,
  false
);
```

*(Ao rodar o aplicativo conectado ao seu próprio banco, utilize esse e-mail e senha para o primeiro login, cadastrar a empresa, os setores e os demais membros da equipe).*

### 5. Configurar as Variáveis de Ambiente (`.env`)
1. No painel do seu projeto no Supabase, acesse **Project Settings > API** e copie a **Project URL** e a chave pública **`anon` `public`**;
2. Na raiz do projeto Flutter (no mesmo nível do arquivo `pubspec.yaml`), crie um arquivo chamado **`.env`** e preencha-o conforme o modelo abaixo:

```env
SUPABASE_URL=[https://seu-projeto.supabase.co](https://seu-projeto.supabase.co)
SUPABASE_ANON_KEY=sua-chave-anon-publica
```

### 6. Instalar as Dependências e Executar
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
