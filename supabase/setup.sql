-- ============================================================================

-- GEOPONTO - SCRIPT COMPLETO DE CONFIGURAÇÃO DO BANCO DE DADOS (SUPABASE)

-- ============================================================================


-- 1. EXTENSÕES NECESSÁRIAS

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


-- 2. TIPOS CUSTOMIZADOS (ENUMS)

DO $$ BEGIN

CREATE TYPE public.tipo_usuario AS ENUM ('ADMINISTRADOR', 'GESTOR', 'FUNCIONARIO');

EXCEPTION WHEN duplicate_object THEN NULL; END $$;


DO $$ BEGIN

CREATE TYPE public.tipo_registro_ponto AS ENUM ('entrada_1', 'saida_1', 'entrada_2', 'saida_2');

EXCEPTION WHEN duplicate_object THEN NULL; END $$;


DO $$ BEGIN

CREATE TYPE public.tipo_ocorrencia AS ENUM (

'falta',

'atraso',

'saida_antecipada',

'esquecimento',

'erro_registro',

'abono'

);

EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- 3. CRIAÇÃO DAS TABELAS (SEM CHAVES ESTRANGEIRAS CIRCULARES INICIALMENTE)

CREATE TABLE public.usuarios (

id uuid NOT NULL,

empresa_id uuid,

setor_id uuid,

nome character varying NOT NULL,

email character varying NOT NULL UNIQUE,

tipo_usuario public.tipo_usuario NOT NULL,

ativo boolean NOT NULL DEFAULT true,

primeiro_acesso boolean NOT NULL DEFAULT true,

criado_em timestamp with time zone NOT NULL DEFAULT now(),

atualizado_em timestamp with time zone NOT NULL DEFAULT now(),

dispositivo_usuario text,

cpf character varying,

CONSTRAINT usuarios_pkey PRIMARY KEY (id),

CONSTRAINT usuarios_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE

);


CREATE TABLE public.empresas (

id uuid NOT NULL DEFAULT gen_random_uuid(),

admin_id uuid UNIQUE,

nome character varying NOT NULL,

cnpj character varying UNIQUE,

latitude_ponto double precision,

longitude_ponto double precision,

raio_permitido_m integer NOT NULL DEFAULT 50,

criado_em timestamp with time zone NOT NULL DEFAULT now(),

atualizado_em timestamp with time zone NOT NULL DEFAULT now(),

CONSTRAINT empresas_pkey PRIMARY KEY (id),

CONSTRAINT fk_empresas_admin FOREIGN KEY (admin_id) REFERENCES public.usuarios(id)

);


CREATE TABLE public.setores (

id uuid NOT NULL DEFAULT gen_random_uuid(),

empresa_id uuid NOT NULL,

gestor_id uuid,

nome character varying NOT NULL,

criado_em timestamp with time zone NOT NULL DEFAULT now(),

atualizado_em timestamp with time zone NOT NULL DEFAULT now(),

CONSTRAINT setores_pkey PRIMARY KEY (id),

CONSTRAINT fk_setores_empresa FOREIGN KEY (empresa_id) REFERENCES public.empresas(id),

CONSTRAINT fk_setores_gestor FOREIGN KEY (gestor_id) REFERENCES public.usuarios(id)

);


-- Adicionando as chaves estrangeiras circulares na tabela usuarios

ALTER TABLE public.usuarios

ADD CONSTRAINT fk_usuarios_empresa FOREIGN KEY (empresa_id) REFERENCES public.empresas(id),

ADD CONSTRAINT fk_usuarios_setor FOREIGN KEY (setor_id) REFERENCES public.setores(id);


CREATE TABLE public.jornadas_trabalho (

id uuid NOT NULL DEFAULT gen_random_uuid(),

carga_horaria_sem integer NOT NULL CHECK (carga_horaria_sem > 0),

criado_em timestamp with time zone NOT NULL DEFAULT now(),

atualizado_em timestamp with time zone NOT NULL DEFAULT now(),

CONSTRAINT jornadas_trabalho_pkey PRIMARY KEY (id)

);


CREATE TABLE public.jornadas_usuarios (

id uuid NOT NULL DEFAULT gen_random_uuid(),

usuario_id uuid NOT NULL,

jornada_id uuid NOT NULL,

data_inicio_vigencia date NOT NULL,

data_fim_vigencia date,

criado_em timestamp with time zone NOT NULL DEFAULT now(),

atualizado_em timestamp with time zone NOT NULL DEFAULT now(),

CONSTRAINT jornadas_usuarios_pkey PRIMARY KEY (id),

CONSTRAINT fk_jornadas_usuarios_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),

CONSTRAINT fk_jornadas_usuarios_jornada FOREIGN KEY (jornada_id) REFERENCES public.jornadas_trabalho(id)

);


CREATE TABLE public.registros_ponto (

id uuid NOT NULL DEFAULT gen_random_uuid(),

usuario_id uuid NOT NULL,

tipo_registro_ponto public.tipo_registro_ponto NOT NULL,

latitude_disp double precision NOT NULL,

longitude_disp double precision NOT NULL,

criado_em timestamp with time zone NOT NULL DEFAULT now(),

CONSTRAINT registros_ponto_pkey PRIMARY KEY (id),

CONSTRAINT fk_registros_ponto_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)

);


CREATE TABLE public.ocorrencias (

id uuid NOT NULL DEFAULT gen_random_uuid(),

usuario_id uuid NOT NULL,

gestor_id uuid NOT NULL,

data_inicio date NOT NULL,

data_fim date,

minutos_abonados integer,

tipo_ocorrencia public.tipo_ocorrencia NOT NULL,

justificativa text NOT NULL,

horario_proposto time without time zone,

aprovada boolean NOT NULL DEFAULT false,

observacao_gestor text,

criado_em timestamp with time zone NOT NULL DEFAULT now(),

atualizado_em timestamp with time zone NOT NULL DEFAULT now(),

CONSTRAINT ocorrencias_pkey PRIMARY KEY (id),

CONSTRAINT fk_ocorrencias_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),

CONSTRAINT fk_ocorrencias_gestor FOREIGN KEY (gestor_id) REFERENCES public.usuarios(id)

);


CREATE TABLE public.fechamentos_mensais (

id uuid NOT NULL DEFAULT gen_random_uuid(),

usuario_id uuid NOT NULL,

mes_referencia date NOT NULL,

minutos_previstos integer NOT NULL,

minutos_trabalhados integer NOT NULL,

minutos_abonados integer NOT NULL,

saldo_minutos integer NOT NULL,

fechada boolean NOT NULL DEFAULT false,

criado_em timestamp with time zone NOT NULL DEFAULT now(),

atualizado_em timestamp with time zone NOT NULL DEFAULT now(),

CONSTRAINT fechamentos_mensais_pkey PRIMARY KEY (id),

CONSTRAINT fk_fechamentos_mensais_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),

CONSTRAINT fechamentos_mensais_usuario_mes_unique UNIQUE (usuario_id, mes_referencia)

);


-- 4. FUNÇÕES RPC E AUXILIARES

CREATE OR REPLACE FUNCTION public.obter_minha_empresa_id()

RETURNS uuid

LANGUAGE sql

STABLE SECURITY DEFINER

SET search_path TO 'public'

AS $function$

SELECT empresa_id FROM public.usuarios WHERE id = auth.uid() LIMIT 1;

$function$;


CREATE OR REPLACE FUNCTION public.criar_membro_equipe(

p_email text,

p_nome text,

p_tipo text,

p_empresa_id uuid,

p_setor_id uuid,

p_cpf text DEFAULT NULL

)

RETURNS json

LANGUAGE plpgsql

SECURITY DEFINER

AS $function$

DECLARE

v_user_id uuid;

v_gestor_atual uuid;

BEGIN

-- Verifica se o setor já tem gestor

IF p_tipo = 'GESTOR' AND p_setor_id IS NOT NULL THEN

SELECT gestor_id INTO v_gestor_atual FROM public.setores WHERE id = p_setor_id;

IF v_gestor_atual IS NOT NULL THEN

RETURN json_build_object('success', false, 'error', 'Este setor já possui um Gestor vinculado a ele.');

END IF;

END IF;


v_user_id := gen_random_uuid();


-- 1. Cria o usuário no Supabase Auth

INSERT INTO auth.users (

instance_id, id, aud, role, email, encrypted_password,

email_confirmed_at, raw_app_meta_data, raw_user_meta_data,

created_at, updated_at, is_sso_user, is_super_admin,

confirmation_token, recovery_token, email_change_token_new, email_change_token_current,

email_change, phone, phone_change, phone_change_token

)

VALUES (

'00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated', p_email,

extensions.crypt('123456', extensions.gen_salt('bf', 10)),

now(), '{"provider":"email","providers":["email"]}',

jsonb_build_object('nome', p_nome, 'tipo_usuario', p_tipo),

now(), now(), false, false,

'', '', '', '',

'', NULL, '', ''

);


-- 2. Cria a identidade vinculada

INSERT INTO auth.identities (

id, user_id, provider_id, identity_data, provider, created_at, updated_at

)

VALUES (

gen_random_uuid(), v_user_id, v_user_id::text,

jsonb_build_object('sub', v_user_id, 'email', p_email, 'email_verified', false, 'phone_verified', false),

'email', now(), now()

);


-- 3. Cria o perfil público

INSERT INTO public.usuarios (id, email, nome, tipo_usuario, empresa_id, setor_id, cpf)

VALUES (v_user_id, p_email, p_nome, p_tipo::public.tipo_usuario, p_empresa_id, p_setor_id, p_cpf)

ON CONFLICT (id) DO UPDATE

SET empresa_id = EXCLUDED.empresa_id,

setor_id = EXCLUDED.setor_id,

nome = EXCLUDED.nome,

tipo_usuario = EXCLUDED.tipo_usuario;


-- 4. Atualiza o setor caso o novo membro seja gestor

IF p_tipo = 'GESTOR' AND p_setor_id IS NOT NULL THEN

UPDATE public.setores SET gestor_id = v_user_id WHERE id = p_setor_id;

END IF;


RETURN json_build_object('success', true, 'message', 'Usuário criado com sucesso');

EXCEPTION

WHEN unique_violation THEN

IF SQLERRM ILIKE '%email%' THEN

RETURN json_build_object('success', false, 'error', 'Este e-mail já está cadastrado no sistema.');

ELSE

RETURN json_build_object('success', false, 'error', 'Já existe um registo com este mesmo dado exclusivo.');

END IF;

WHEN OTHERS THEN

RETURN json_build_object('success', false, 'error', 'Erro interno no banco: ' || SQLERRM);

END;

$function$;


-- 5. HABILITAR ROW LEVEL SECURITY (RLS) EM TODAS AS TABELAS

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.setores ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.jornadas_trabalho ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.jornadas_usuarios ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.registros_ponto ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.ocorrencias ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.fechamentos_mensais ENABLE ROW LEVEL SECURITY;


-- 6. POLÍTICAS DE SEGURANÇA (RLS POLICIES)


-- Tabela: empresas

CREATE POLICY "Permitir leitura da própria empresa"

ON public.empresas FOR SELECT TO authenticated

USING ((id = obter_minha_empresa_id()) OR (admin_id = auth.uid()));


CREATE POLICY "empresas_admin_all"

ON public.empresas FOR ALL TO authenticated

USING (admin_id = auth.uid())

WITH CHECK (admin_id = auth.uid());


-- Tabela: setores

CREATE POLICY "Gestão de setores pelo admin"

ON public.setores FOR ALL TO authenticated

USING (EXISTS (

SELECT 1 FROM public.empresas

WHERE empresas.id = setores.empresa_id AND empresas.admin_id = auth.uid()

));


CREATE POLICY "Permitir leitura de setores"

ON public.setores FOR SELECT TO authenticated

USING (true);


-- Tabela: usuarios

CREATE POLICY "Admin pode ler usuarios da sua empresa"

ON public.usuarios FOR SELECT TO authenticated

USING (

(id = auth.uid()) OR

(empresa_id IN (SELECT empresas.id FROM public.empresas WHERE empresas.admin_id = auth.uid()))

);


CREATE POLICY "Gestores podem atualizar membros do seu setor"

ON public.usuarios FOR UPDATE TO authenticated

USING (EXISTS (

SELECT 1 FROM public.setores

WHERE setores.id = usuarios.setor_id AND setores.gestor_id = auth.uid()

));


CREATE POLICY "Permitir leitura de usuarios para equipe"

ON public.usuarios FOR SELECT TO authenticated

USING (true);


CREATE POLICY "Permitir usuário atualizar o próprio perfil"

ON public.usuarios FOR UPDATE TO public

USING (auth.uid() = id);


CREATE POLICY "usuarios_admin_all"

ON public.usuarios FOR ALL TO authenticated

USING (EXISTS (

SELECT 1 FROM public.empresas

WHERE empresas.admin_id = auth.uid() AND empresas.id = usuarios.empresa_id

))

WITH CHECK (EXISTS (

SELECT 1 FROM public.empresas

WHERE empresas.admin_id = auth.uid() AND empresas.id = usuarios.empresa_id

));


CREATE POLICY "usuarios_select_proprio"

ON public.usuarios FOR SELECT TO authenticated

USING (id = auth.uid());


-- Tabela: jornadas_trabalho

CREATE POLICY "Permitir leitura de jornadas"

ON public.jornadas_trabalho FOR SELECT TO authenticated

USING (true);


-- Tabela: jornadas_usuarios

CREATE POLICY "Apenas Admin e Gestor podem alterar jornadas"

ON public.jornadas_usuarios FOR ALL TO authenticated

USING ((SELECT usuarios.tipo_usuario FROM public.usuarios WHERE usuarios.id = auth.uid()) = ANY (ARRAY['ADMINISTRADOR'::public.tipo_usuario, 'GESTOR'::public.tipo_usuario]))

WITH CHECK ((SELECT usuarios.tipo_usuario FROM public.usuarios WHERE usuarios.id = auth.uid()) = ANY (ARRAY['ADMINISTRADOR'::public.tipo_usuario, 'GESTOR'::public.tipo_usuario]));


CREATE POLICY "Colaborador le proprias jornadas"

ON public.jornadas_usuarios FOR SELECT TO authenticated

USING (usuario_id = auth.uid());


CREATE POLICY "Permitir leitura de jornadas dos usuarios"

ON public.jornadas_usuarios FOR SELECT TO authenticated

USING (true);


-- Tabela: registros_ponto

CREATE POLICY "Colaborador le proprios pontos"

ON public.registros_ponto FOR SELECT TO authenticated

USING (usuario_id = auth.uid());


CREATE POLICY "Gestor e Admin leem pontos da equipe"

ON public.registros_ponto FOR SELECT TO authenticated

USING ((SELECT usuarios.tipo_usuario FROM public.usuarios WHERE usuarios.id = auth.uid()) = ANY (ARRAY['ADMINISTRADOR'::public.tipo_usuario, 'GESTOR'::public.tipo_usuario]));


CREATE POLICY "Permitir inserção do próprio ponto"

ON public.registros_ponto FOR INSERT TO authenticated

WITH CHECK (usuario_id = auth.uid());


-- Tabela: fechamentos_mensais

CREATE POLICY "Colaborador le proprio fechamento"

ON public.fechamentos_mensais FOR SELECT TO authenticated

USING (usuario_id = auth.uid());


CREATE POLICY "Gestor e Admin gerenciam fechamentos"

ON public.fechamentos_mensais FOR ALL TO authenticated

USING ((SELECT usuarios.tipo_usuario FROM public.usuarios WHERE usuarios.id = auth.uid()) = ANY (ARRAY['ADMINISTRADOR'::public.tipo_usuario, 'GESTOR'::public.tipo_usuario]));


-- Tabela: ocorrencias

CREATE POLICY "Colaborador cria ocorrencias"

ON public.ocorrencias FOR INSERT TO authenticated

WITH CHECK (usuario_id = auth.uid());


CREATE POLICY "Colaborador le proprias ocorrencias"

ON public.ocorrencias FOR SELECT TO authenticated

USING ((usuario_id = auth.uid()) OR (gestor_id = auth.uid()));


CREATE POLICY "Colaborador deleta propria ocorrencia"

ON public.ocorrencias FOR DELETE TO authenticated

USING (usuario_id = auth.uid());


CREATE POLICY "Colaborador atualiza propria ocorrencia"

ON public.ocorrencias FOR UPDATE TO authenticated

USING (usuario_id = auth.uid());


CREATE POLICY "Gestor e Admin atualizam ocorrencias"

ON public.ocorrencias FOR UPDATE TO authenticated

USING (

(gestor_id = auth.uid()) OR

((SELECT usuarios.tipo_usuario FROM public.usuarios WHERE usuarios.id = auth.uid()) = ANY (ARRAY['ADMINISTRADOR'::public.tipo_usuario, 'GESTOR'::public.tipo_usuario]))

);


CREATE POLICY "ocorrencias_update_autorizado_avaliacao"

ON public.ocorrencias AS PERMISSIVE FOR UPDATE TO authenticated

USING (

((usuario_id = auth.uid()) AND (aprovada = false) AND (minutos_abonados IS NULL))

OR (

(gestor_id = auth.uid())

AND (data_inicio >= (date_trunc('month'::text, (((now() AT TIME ZONE 'America/Sao_Paulo'::text))::date)::timestamp with time zone))::date)

AND (data_inicio < ((date_trunc('month'::text, (((now() AT TIME ZONE 'America/Sao_Paulo'::text))::date)::timestamp with time zone) + '1 mon'::interval))::date)

AND (NOT (EXISTS (

SELECT 1 FROM public.fechamentos_mensais fechamento

WHERE fechamento.usuario_id = ocorrencias.usuario_id

AND fechamento.mes_referencia = (date_trunc('month'::text, (ocorrencias.data_inicio)::timestamp with time zone))::date

AND fechamento.fechada = true

)))

AND (EXISTS (

SELECT 1 FROM (public.usuarios ator JOIN public.usuarios titular ON titular.id = ocorrencias.usuario_id)

WHERE ator.id = auth.uid() AND ator.ativo = true AND titular.ativo = true

AND ator.empresa_id = titular.empresa_id

AND (

((ator.tipo_usuario)::text = 'GESTOR'::text AND (titular.tipo_usuario)::text = 'FUNCIONARIO'::text AND EXISTS (

SELECT 1 FROM public.setores setor WHERE setor.id = titular.setor_id AND setor.gestor_id = ator.id

))

OR ((ator.tipo_usuario)::text = 'ADMINISTRADOR'::text AND (titular.tipo_usuario)::text = 'GESTOR'::text)

)

))

)

)

WITH CHECK (

((usuario_id = auth.uid()) AND (aprovada = false) AND (minutos_abonados IS NULL))

OR (

(usuario_id <> auth.uid())

AND (gestor_id = auth.uid())

AND (data_inicio >= (date_trunc('month'::text, (((now() AT TIME ZONE 'America/Sao_Paulo'::text))::date)::timestamp with time zone))::date)

AND (data_inicio < ((date_trunc('month'::text, (((now() AT TIME ZONE 'America/Sao_Paulo'::text))::date)::timestamp with time zone) + '1 mon'::interval))::date)

AND (NOT (EXISTS (

SELECT 1 FROM public.fechamentos_mensais fechamento

WHERE fechamento.usuario_id = ocorrencias.usuario_id

AND fechamento.mes_referencia = (date_trunc('month'::text, (ocorrencias.data_inicio)::timestamp with time zone))::date

AND fechamento.fechada = true

)))

AND (

((aprovada = false) AND (minutos_abonados IS NULL))

OR ((aprovada = true) AND (minutos_abonados > 0) AND (minutos_abonados <= 720) AND (minutos_abonados = (COALESCE(((EXTRACT(hour FROM horario_proposto))::integer * 60), 0) + COALESCE((EXTRACT(minute FROM horario_proposto))::integer, 0))))

OR ((aprovada = false) AND (minutos_abonados = 0))

)

AND (EXISTS (

SELECT 1 FROM (public.usuarios ator JOIN public.usuarios titular ON titular.id = ocorrencias.usuario_id)

WHERE ator.id = auth.uid() AND ator.ativo = true AND titular.ativo = true

AND ator.empresa_id = titular.empresa_id

AND (

((ator.tipo_usuario)::text = 'GESTOR'::text AND (titular.tipo_usuario)::text = 'FUNCIONARIO'::text AND EXISTS (

SELECT 1 FROM public.setores setor WHERE setor.id = titular.setor_id AND setor.gestor_id = ator.id

))

OR ((ator.tipo_usuario)::text = 'ADMINISTRADOR'::text AND (titular.tipo_usuario)::text = 'GESTOR'::text)

)

))

)

);


CREATE POLICY "ocorrencias_update_restricao_avaliacao"

ON public.ocorrencias AS RESTRICTIVE FOR UPDATE TO authenticated

USING (

((usuario_id = auth.uid()) AND (aprovada = false) AND (minutos_abonados IS NULL))

OR (

(gestor_id = auth.uid())

AND (data_inicio >= (date_trunc('month'::text, (((now() AT TIME ZONE 'America/Sao_Paulo'::text))::date)::timestamp with time zone))::date)

AND (data_inicio < ((date_trunc('month'::text, (((now() AT TIME ZONE 'America/Sao_Paulo'::text))::date)::timestamp with time zone) + '1 mon'::interval))::date)

AND (NOT (EXISTS (

SELECT 1 FROM public.fechamentos_mensais fechamento

WHERE fechamento.usuario_id = ocorrencias.usuario_id

AND fechamento.mes_referencia = (date_trunc('month'::text, (ocorrencias.data_inicio)::timestamp with time zone))::date

AND fechamento.fechada = true

)))

AND (EXISTS (

SELECT 1 FROM (public.usuarios ator JOIN public.usuarios titular ON titular.id = ocorrencias.usuario_id)

WHERE ator.id = auth.uid() AND ator.ativo = true AND titular.ativo = true

AND ator.empresa_id = titular.empresa_id

AND (

((ator.tipo_usuario)::text = 'GESTOR'::text AND (titular.tipo_usuario)::text = 'FUNCIONARIO'::text AND EXISTS (

SELECT 1 FROM public.setores setor WHERE setor.id = titular.setor_id AND setor.gestor_id = ator.id

))

OR ((ator.tipo_usuario)::text = 'ADMINISTRADOR'::text AND (titular.tipo_usuario)::text = 'GESTOR'::text)

)

))

)

)

WITH CHECK (

((usuario_id = auth.uid()) AND (aprovada = false) AND (minutos_abonados IS NULL))

OR (

(usuario_id <> auth.uid())

AND (gestor_id = auth.uid())

AND (data_inicio >= (date_trunc('month'::text, (((now() AT TIME ZONE 'America/Sao_Paulo'::text))::date)::timestamp with time zone))::date)

AND (data_inicio < ((date_trunc('month'::text, (((now() AT TIME ZONE 'America/Sao_Paulo'::text))::date)::timestamp with time zone) + '1 mon'::interval))::date)

AND (NOT (EXISTS (

SELECT 1 FROM public.fechamentos_mensais fechamento

WHERE fechamento.usuario_id = ocorrencias.usuario_id

AND fechamento.mes_referencia = (date_trunc('month'::text, (ocorrencias.data_inicio)::timestamp with time zone))::date

AND fechamento.fechada = true

)))

AND (

((aprovada = false) AND (minutos_abonados IS NULL))

OR ((aprovada = true) AND (minutos_abonados > 0) AND (minutos_abonados <= 720) AND (minutos_abonados = (COALESCE(((EXTRACT(hour FROM horario_proposto))::integer * 60), 0) + COALESCE((EXTRACT(minute FROM horario_proposto))::integer, 0))))

OR ((aprovada = false) AND (minutos_abonados = 0))

)

AND (EXISTS (

SELECT 1 FROM (public.usuarios ator JOIN public.usuarios titular ON titular.id = ocorrencias.usuario_id)

WHERE ator.id = auth.uid() AND ator.ativo = true AND titular.ativo = true

AND ator.empresa_id = titular.empresa_id

AND (

((ator.tipo_usuario)::text = 'GESTOR'::text AND (titular.tipo_usuario)::text = 'FUNCIONARIO'::text AND EXISTS (

SELECT 1 FROM public.setores setor WHERE setor.id = titular.setor_id AND setor.gestor_id = ator.id

))

OR ((ator.tipo_usuario)::text = 'ADMINISTRADOR'::text AND (titular.tipo_usuario)::text = 'GESTOR'::text)

)

))

)

);


-- 7. CARGA INICIAL (JORNADAS PADRÃO)

INSERT INTO public.jornadas_trabalho (carga_horaria_sem)

VALUES (30), (40), (44);