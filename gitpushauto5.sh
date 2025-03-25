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

# 1. Verificar si es repo Git
if [ ! -d ".git" ]; then
    echo "⚠️  No es un repo Git. ¿Lo creo? (s/n): "
    read resp
    if [[ "$resp" == "s" ]]; then
        git init
        echo "✅ Repo Git creado."
    else
        echo "❌ Abortando."
        exit 1
    fi
fi

# 2. Configurar identidad
if ! git config user.name >/dev/null; then
    echo "👤 Falta nombre para los commits:"
    read -p "Nombre: " nombre
    git config user.name "$nombre"
fi

if ! git config user.email >/dev/null; then
    echo "📧 Falta email para los commits:"
    read -p "Email: " email
    git config user.email "$email"
fi

# 3. Renombrar rama si hace falta
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
if [[ "$current_branch" != "$branch" ]]; then
    echo "🌱 Renombrando rama '$current_branch' a '$branch'..."
    git branch -m "$branch"
fi

# 4. Hacer commit si no hay
if ! git rev-parse HEAD >/dev/null 2>&1; then
    echo "📭 No hay commits. ¿Querés que haga el primero? (s/n): "
    read resp
    if [[ "$resp" == "s" ]]; then
        git add .
        git commit -m "Primer commit automático"
        echo "✅ Commit hecho."
    else
        echo "❌ Sin commits no se puede pushear. Abortando."
        exit 1
    fi
fi

# 5. Crear repo en GitHub si no existe
check_repo=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $pat" https://api.github.com/repos/$usuario/$repo)
if [[ "$check_repo" == "404" ]]; then
    echo "🧱 El repo '$repo' no existe en GitHub. ¿Querés crearlo? (s/n): "
    read resp
    if [[ "$resp" == "s" ]]; then
        create_repo=$(curl -s -H "Authorization: token $pat" https://api.github.com/user/repos \
        -d "{\"name\":\"$repo\"}")
        if echo "$create_repo" | grep -q "\"full_name\": \"$usuario/$repo\""; then
            echo "✅ Repo '$repo' creado en GitHub."
        else
            echo "❌ Error creando el repo en GitHub."
            echo "$create_repo"
            exit 1
        fi
    else
        echo "❌ Sin repo remoto, no hay push. Abortando."
        exit 1
    fi
fi

# 6. Configurar remote si hace falta
expected_url="https://github.com/$usuario/$repo.git"
if ! git remote get-url "$remote" &>/dev/null; then
    git remote add "$remote" "$expected_url"
    echo "✅ Remote '$remote' agregado."
else
    current_url=$(git remote get-url "$remote")
    if [[ "$current_url" != "$expected_url" ]]; then
        echo "🔧 Corrigiendo URL de remote '$remote'..."
        git remote set-url "$remote" "$expected_url"
    fi
fi

# 7. Push con token
token_url=$(echo "$expected_url" | sed "s|https://|https://$usuario:$pat@|")

echo "🚀 Haciendo push a '$branch' en '$remote' usando token (modo todo en uno)..."
git push "$token_url" "$branch"

if [[ $? -eq 0 ]]; then
    echo "✅ ¡Push completado, Guille!"
else
    echo "❌ Falló el push. Revisá el token o los permisos."
fi
