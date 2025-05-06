-- Initialize Supabase schema

-- Create necessary roles
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;

-- Create authenticator role
CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'postgres';
GRANT anon TO authenticator;
GRANT authenticated TO authenticator;
GRANT service_role TO authenticator;

-- Create supabase_auth schema and extensions
CREATE SCHEMA IF NOT EXISTS auth;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- Create storage schema
CREATE SCHEMA IF NOT EXISTS storage;

-- Create public schema tables and functions
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  updated_at TIMESTAMP WITH TIME ZONE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  website TEXT,
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Set up Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create security policies
CREATE POLICY "Public profiles are viewable by everyone."
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile."
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile."
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Create a trigger to set updated_at on profiles
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_updated_at();

-- Create a function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'avatar_url');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger on auth.users to create a profile for new users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();