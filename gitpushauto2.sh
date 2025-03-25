#!/bin/bash

echo -n "🐙 Usuario de GitHub: "
read usuario

echo -n "📦 Nombre del repo en GitHub (ej: gitpush_pat): "
read repo

echo -n "🌐 Nombre del remote (default: origin): "
read remote
remote=${remote:-origin}

echo -n "🌿 Nombre de la rama (default: main): "
read branch
branch=${branch:-main}

echo -n "🔑 Token personal (PAT): "
read -s pat
echo ""

echo "🧠 Analizando entorno... dame un segundo."

# 1. ¿Es un repo git?
if [ ! -d ".git" ]; then
    echo "⚠️  Guille, este directorio no es un repo Git."
    echo -n "🔥 ¿Querés que lo inicialice por vos? (s/n): "
    read resp
    if [[ "$resp" == "s" ]]; then
        git init
        echo "✅ Listo, repo inicializado."
    else
        echo "❌ Bueno, sin Git no hay magia. Abortando."
        exit 1
    fi
fi

# Si la rama inicial no es 'main', la renombramos
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
if [[ "$current_branch" != "$branch" ]]; then
    echo "🌱 Renombrando rama '$current_branch' a '$branch'..."
    git branch -m "$branch"
fi


# 1A Configurar identidad si no está
if ! git config user.name >/dev/null; then
    echo "👤 No hay identidad de usuario configurada."
    echo -n "Nombre para los commits (ej: Guille Frassia): "
    read nombre
    git config user.name "$nombre"
fi

if ! git config user.email >/dev/null; then
    echo -n "Email para los commits (ej: guille@ejemplo.com): "
    read email
    git config user.email "$email"
fi



# 2. ¿Hay commits?
if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "📭 No hay commits todavía."
    echo -n "📌 ¿Querés que haga el primer commit con todo lo actual? (s/n): "
    read resp
    if [[ "$resp" == "s" ]]; then
        git add .
        git commit -m "Primer commit automático"
        echo "✅ Todo listo. Ya tenés un commit."
    else
        echo "❌ Sin commits no hay push. Abortando."
        exit 1
    fi
fi

# 3. ¿Hay remote?
if ! git remote get-url "$remote" &>/dev/null; then
    echo "🌐 No encontré el remote '$remote'."
    echo -n "➕ ¿Querés que lo agregue apuntando a GitHub? (s/n): "
    read resp
    if [[ "$resp" == "s" ]]; then
        remote_url="https://github.com/$usuario/$repo.git"
        git remote add "$remote" "$remote_url"
        echo "✅ Remote agregado: $remote_url"
    else
        echo "❌ Sin remote no puedo empujar nada. Abortando."
        exit 1
    fi
fi

# 4. Push con token (sin dejar rastros)
remote_url=$(git remote get-url "$remote")
token_url=$(echo "$remote_url" | sed "s|https://|https://$usuario:$pat@|")

echo "🚀 Haciendo push a '$branch' en '$remote' usando token (modo ninja)..."
git push "$token_url" "$branch"

echo "✅ ¡Push completado, Guille! Todo salió redondo."
