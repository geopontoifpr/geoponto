🕐 GeoPonto
Aplicativo mobile de controle de ponto eletrônico para pequenas e médias empresas, com validação por geolocalização e biometria.

https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter
https://img.shields.io/badge/Dart-3.5-0175C2?logo=dart
https://img.shields.io/badge/Supabase-BaaS-3ECF8E?logo=supabase
https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql
https://img.shields.io/badge/Android-8.0+-3DDC84?logo=android

📋 Sobre o projeto
O GeoPonto é um sistema de registro eletrônico de ponto (REP-P) desenvolvido como Projeto Integrador do curso de Tecnologia em Análise e Desenvolvimento de Sistemas do Instituto Federal do Paraná.

A aplicação substitui registradores físicos (REP-C) por uma solução móvel que atende às exigências da Portaria MTP nº 671/2021, oferecendo:

📍 Validação por geolocalização — o registro só é aceito dentro do perímetro definido pela empresa (Podendo não ter perimetro tambem.);

🔒 Autenticação biométrica — validação da identidade via biometria do dispositivo;

📊 Cálculo automático de jornada — horas trabalhadas, extras, atrasos e banco de horas;

✅ Fluxo de aprovação — gestores revisam e aprovam correções e fechamentos mensais.

🎯 Objetivos
Desenvolver um aplicativo mobile de ponto eletrônico para registro de frequência e jornada de trabalho;

Permitir o controle de horários, validação dos registros e acompanhamento por gestores;

Reduzir erros manuais e automatizar o cálculo de horas extras, atrasos e banco de horas.

👥 Perfis de usuário
O sistema possui três níveis de acesso:

Perfil	Descrição	Principais permissões
ADMINISTRADOR	Único por instalação, inserido manualmente no banco	Cadastra a empresa, gestores, funcionários, setores e jornadas
GESTOR	Responsável por um setor específico	Cadastra funcionários do seu setor, aprova ocorrências e fechamentos
FUNCIONÁRIO	Colaborador comum	Registra ponto, solicita correções, consulta espelho de ponto
🏗️ Arquitetura
O projeto utiliza uma arquitetura BaaS (Backend as a Service) com o Supabase, eliminando a necessidade de um backend próprio:

text
Flutter (Android)
       │
       │  Supabase SDK
       ▼
┌─────────────────┐
│  Supabase Auth  │ ──── auth.users
└─────────────────┘
       │
       │  JWT
       ▼
┌─────────────────┐
│  PostgreSQL     │
│  + RLS          │
└─────────────────┘
       │
       └──── public.usuarios
                │
                ├── empresas
                ├── setores
                ├── jornadas_trabalho
                ├── jornadas_usuarios
                ├── registros_ponto
                ├── ocorrencias
                └── fechamentos_mensais
Princípios
Autenticação: delegada ao Supabase Auth (auth.users) — sem senhas armazenadas em tabelas do app;

Autorização: aplicada via Row Level Security (RLS) usando auth.uid() e relacionamentos entre tabelas;

CRUD: realizado diretamente pelo SDK do Flutter, sem RPCs desnecessárias;

Operações administrativas: concentradas em uma Edge Function para criação de usuários (uso seguro da service_role).

🚀 Tecnologias
Frontend: Flutter 3.24 / Dart 3.5 (Android 8.0+)

Backend as a Service: Supabase

Auth (e-mail/senha, JWT, sessões)

PostgreSQL 15 com Row Level Security

Edge Functions (Deno) para operações administrativas

Geolocalização: plugin de GPS do dispositivo

Biometria: leitor biométrico nativo do Android

📱 Funcionalidades
Requisitos funcionais principais
✅ Cadastro e configuração da empresa (nome, CNPJ, perímetro geográfico)

✅ Cadastro e gerenciamento de gestores e funcionários

✅ Autenticação por e-mail e senha

✅ Registro de ponto com validação de geolocalização e biometria

✅ Consulta de jornada com filtros por período

✅ Consulta de saldo de horas

✅ Solicitação de correção de registro

✅ Dashboard administrativo (aprovações)

✅ Aprovação mensal de fechamento

✅ Logout


🔐 Segurança
Row Level Security (RLS)
Todas as tabelas possuem RLS habilitado. As políticas são baseadas em auth.uid() e em funções auxiliares SECURITY DEFINER para evitar recursão:


📂 Estrutura do repositório
text
geoponto/
├── app/                        # Aplicativo Flutter
│   ├── lib/
│   │   ├── core/               # Configurações, temas, constantes
│   │   ├── features/           # Módulos por domínio
│   │   │   ├── auth/
│   │   │   ├── empresa/
│   │   │   ├── usuarios/
│   │   │   ├── ponto/
│   │   │   └── fechamento/
│   │   └── main.dart
│   └── pubspec.yaml
├── supabase/
│   ├── migrations/             # Migrations SQL versionadas
│   ├── functions/              # Edge Functions
│   │   └── create-user/
│   └── seed.sql
├── docs/                       # Documentação do projeto
└── README.md

🛠️ Configuração do ambiente
Pré-requisitos
Flutter SDK 3.24+

Dart 3.5+

Android SDK (API 26+)

Conta no Supabase

Supabase CLI

Passos
Clonar o repositório

bash
git clone https://github.com/seu-usuario/geoponto.git
cd geoponto
Configurar o Supabase

bash
supabase init
supabase link --project-ref <seu-project-ref>
supabase db push
Configurar variáveis de ambiente do Flutter

Crie o arquivo .env na raiz do app:

env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anonima
Instalar dependências e executar

bash
cd app
flutter pub get
flutter run

👨‍💻 Equipe
Caroline Viana de Souza
Giovaine Orso Vieira
Leonardo Nogueira Hilgenberg

Instituição: Instituto Federal do Paraná
Curso: Tecnologia em Análise e Desenvolvimento de Sistemas
Disciplina: Projeto Integrador

📄 Licença
Projeto acadêmico desenvolvido para fins educacionais.