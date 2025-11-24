#!/bin/bash
# Script de Deploy Automático para GitHub
# Certificados IA e Bibliotecas - EBADS Ovar

set -e  # Parar em caso de erro

echo "🚀 Iniciando Deploy Automático..."
echo "================================"
echo ""

# Configurações
REPO_URL="https://github.com/dpolonia/202511-Ovar.git"
REPO_DIR="/tmp/202511-ovar-deploy"
SOURCE_DIR="/mnt/user-data/outputs"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para mensagens
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Verificar se git está instalado
if ! command -v git &> /dev/null; then
    log_error "Git não está instalado!"
    exit 1
fi

log_info "Git encontrado"

# Limpar diretório temporário se existir
if [ -d "$REPO_DIR" ]; then
    log_warn "Removendo diretório temporário existente..."
    rm -rf "$REPO_DIR"
fi

# Clonar repositório
log_info "Clonando repositório..."
git clone "$REPO_URL" "$REPO_DIR"

if [ $? -ne 0 ]; then
    log_error "Falha ao clonar repositório!"
    log_warn "Verifique se tem acesso ao repositório e se as credenciais estão corretas"
    exit 1
fi

cd "$REPO_DIR"

# Configurar git (se ainda não estiver configurado)
if [ -z "$(git config user.name)" ]; then
    log_info "Configurando git user..."
    git config user.name "Daniel Polonia"
    git config user.email "dpolonia@ua.pt"
fi

log_info "Repositório clonado com sucesso"

# Remover ficheiros antigos (exceto README.md e .git)
log_info "Limpando ficheiros antigos..."
find . -type f ! -name 'README.md' ! -path './.git/*' -delete
find . -type d -empty ! -path './.git/*' -delete

# Copiar novos ficheiros
log_info "Copiando novos certificados..."

# Certificados HTML
cp "$SOURCE_DIR"/certificado_*.html . 2>/dev/null || log_warn "Nenhum certificado encontrado"

# Página índice
cp "$SOURCE_DIR/index.html" . 2>/dev/null || log_warn "index.html não encontrado"

# Configuração Vercel
cp "$SOURCE_DIR/vercel.json" . 2>/dev/null || log_warn "vercel.json não encontrado"

# .gitignore
cp "$SOURCE_DIR/.gitignore" . 2>/dev/null || log_warn ".gitignore não encontrado"

# README.md (atualizar)
if [ -f "$SOURCE_DIR/README.md" ]; then
    cp "$SOURCE_DIR/README.md" .
    log_info "README.md atualizado"
fi

# Scripts Python (para manutenção futura)
cp "$SOURCE_DIR/gerar_certificados_anonimos.py" . 2>/dev/null || log_warn "Script de geração não encontrado"

# NÃO copiar ficheiros privados
log_warn "Ficheiros privados não serão copiados (CODIGOS_PRIVADOS.md, mapeamento_privado.json)"

# Contar ficheiros
NUM_CERT=$(ls -1 certificado_*.html 2>/dev/null | wc -l)
log_info "Total de certificados: $NUM_CERT"

# Verificar se há alterações
if [ -z "$(git status --porcelain)" ]; then
    log_warn "Nenhuma alteração detectada. Nada para fazer deploy."
    cd /
    rm -rf "$REPO_DIR"
    exit 0
fi

# Mostrar status
echo ""
echo "Ficheiros alterados:"
echo "-------------------"
git status --short
echo ""

# Adicionar todos os ficheiros
log_info "Adicionando ficheiros ao git..."
git add .

# Commit
COMMIT_MSG="Adicionar certificados anónimos IA e Bibliotecas - $NUM_CERT formandos

- Certificados com IDs anónimos (001-027)
- QR codes incorporados em cada certificado
- Página de acesso com busca por código
- Proteção de privacidade dos formandos

Data: $(date '+%Y-%m-%d %H:%M:%S')"

log_info "Criando commit..."
git commit -m "$COMMIT_MSG"

# Push para o repositório
echo ""
log_warn "Pronto para fazer push para o GitHub..."
echo "Repositório: $REPO_URL"
echo "Branch: main"
echo ""

# Tentar push
log_info "Fazendo push para o GitHub..."
if git push origin main; then
    log_info "Push realizado com sucesso!"
    echo ""
    echo "================================"
    echo "✅ DEPLOY CONCLUÍDO COM SUCESSO!"
    echo "================================"
    echo ""
    echo "🌐 O Vercel irá automaticamente fazer deploy em 1-2 minutos"
    echo "📊 Acompanhe em: https://vercel.com/daniels-projects-cfa01595/202511-ovar2"
    echo "🔗 Site: https://202511-ovar2.vercel.app"
    echo ""
else
    log_error "Falha ao fazer push!"
    echo ""
    echo "Possíveis causas:"
    echo "1. Não tem permissões de escrita no repositório"
    echo "2. Credenciais não configuradas"
    echo "3. Problemas de rede"
    echo ""
    echo "Para configurar credenciais:"
    echo "git config --global user.name 'Seu Nome'"
    echo "git config --global user.email 'seu@email.com'"
    echo ""
    cd /
    rm -rf "$REPO_DIR"
    exit 1
fi

# Limpar
cd /
rm -rf "$REPO_DIR"
log_info "Diretório temporário removido"

echo ""
echo "🎉 Processo concluído!"
