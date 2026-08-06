#!/usr/bin/env bash
#
# enhance-premium-v2.sh
# ---------------------------------------------------------------------------
# À exécuter APRÈS enhance-premium.sh. Corrige et étend les fonctionnalités
# premium selon vos retours :
#
#   1. Le calculateur de devis (/devis-instantane) fonctionne maintenant
#      pour N'IMPORTE QUEL PAYS (Afrique, Asie, et au-delà) avec sa propre
#      devise. Les prix de base sont en USD et convertis automatiquement
#      via un taux de change en temps réel. Un nouvel écran "Tarifs" dans
#      le dashboard permet de changer les prix sans toucher au code.
#
#   2. Correction du bug d'affichage en mode portrait sur /audit-instantane
#      (le bouton "Analyser" réutilisait une classe CSS de la navbar qui
#      est masquée sous 900px de large — il est maintenant sur sa propre
#      classe, toujours visible).
#
#   3. Ajout d'instructions visibles directement sur la page pour obtenir
#      une clé API PageSpeed gratuite (le quota sans clé est très limité,
#      d'où le message "Trop de demandes en ce moment"), + mise en cache
#      des résultats pour économiser le quota.
#
# Usage (à la racine du projet, après enhance-premium.sh) :
#   chmod +x enhance-premium-v2.sh
#   ./enhance-premium-v2.sh
#   npm install
#   npm run dev
#
# Puis dans Supabase → SQL Editor, exécutez le contenu de :
#   supabase/pricing_settings.sql
# (une seule fois) pour activer l'édition des tarifs depuis le dashboard.
# ---------------------------------------------------------------------------

set -euo pipefail

if [ ! -f "package.json" ] || [ ! -d "src" ]; then
  echo "❌ Ce script doit être exécuté à la racine du projet (là où se trouvent package.json et src/)."
  exit 1
fi

if [ ! -f "src/pages/AuditInstantane.jsx" ] || [ ! -f "src/pages/DevisInstantane.jsx" ]; then
  echo "❌ Il semble que enhance-premium.sh n'a pas encore été exécuté ici."
  echo "   Lancez d'abord enhance-premium.sh, puis relancez ce script."
  exit 1
fi

echo "🚀 Mise à niveau vers les tarifs multi-devises + corrections..."

backup() {
  local file="$1"
  if [ -f "$file" ] && [ ! -f "$file.bak2" ]; then
    cp "$file" "$file.bak2"
    echo "   🗂  Sauvegarde créée : $file.bak2"
  fi
}

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  backup "$path"
}

# ---------------------------------------------------------------------------
# 1. src/constants/countries.js — pays, villes et devises (Afrique, Asie, +)
# ---------------------------------------------------------------------------

write_file "src/constants/countries.js"
cat > "src/constants/countries.js" <<'EOF'
// Référentiel pays / villes / devises pour le calculateur de devis.
// Couvre l'Afrique et l'Asie en priorité, avec quelques marchés
// internationaux supplémentaires, plus une option "Autre pays" en
// texte libre pour n'importe où ailleurs dans le monde.

export const OTHER_COUNTRY = "__other__";

export const CURRENCIES = [
  { code: "USD", symbol: "$", label: "Dollar américain (USD)" },
  { code: "EUR", symbol: "€", label: "Euro (EUR)" },
  { code: "GBP", symbol: "£", label: "Livre sterling (GBP)" },
  { code: "TZS", symbol: "TSh", label: "Shilling tanzanien (TZS)" },
  { code: "KES", symbol: "KSh", label: "Shilling kényan (KES)" },
  { code: "UGX", symbol: "USh", label: "Shilling ougandais (UGX)" },
  { code: "RWF", symbol: "FRw", label: "Franc rwandais (RWF)" },
  { code: "CDF", symbol: "FC", label: "Franc congolais (CDF)" },
  { code: "NGN", symbol: "₦", label: "Naira nigérian (NGN)" },
  { code: "GHS", symbol: "GH₵", label: "Cedi ghanéen (GHS)" },
  { code: "ZAR", symbol: "R", label: "Rand sud-africain (ZAR)" },
  { code: "EGP", symbol: "E£", label: "Livre égyptienne (EGP)" },
  { code: "MAD", symbol: "DH", label: "Dirham marocain (MAD)" },
  { code: "XOF", symbol: "CFA", label: "Franc CFA - UEMOA (XOF)" },
  { code: "XAF", symbol: "FCFA", label: "Franc CFA - CEMAC (XAF)" },
  { code: "ETB", symbol: "Br", label: "Birr éthiopien (ETB)" },
  { code: "ZMW", symbol: "ZK", label: "Kwacha zambien (ZMW)" },
  { code: "DZD", symbol: "DA", label: "Dinar algérien (DZD)" },
  { code: "TND", symbol: "DT", label: "Dinar tunisien (TND)" },
  { code: "MZN", symbol: "MT", label: "Metical mozambicain (MZN)" },
  { code: "INR", symbol: "₹", label: "Roupie indienne (INR)" },
  { code: "CNY", symbol: "¥", label: "Yuan chinois (CNY)" },
  { code: "AED", symbol: "د.إ", label: "Dirham des Émirats (AED)" },
  { code: "SAR", symbol: "﷼", label: "Riyal saoudien (SAR)" },
  { code: "QAR", symbol: "ر.ق", label: "Riyal qatari (QAR)" },
  { code: "IDR", symbol: "Rp", label: "Roupie indonésienne (IDR)" },
  { code: "PHP", symbol: "₱", label: "Peso philippin (PHP)" },
  { code: "MYR", symbol: "RM", label: "Ringgit malaisien (MYR)" },
  { code: "SGD", symbol: "S$", label: "Dollar de Singapour (SGD)" },
  { code: "THB", symbol: "฿", label: "Baht thaïlandais (THB)" },
  { code: "VND", symbol: "₫", label: "Dong vietnamien (VND)" },
  { code: "PKR", symbol: "₨", label: "Roupie pakistanaise (PKR)" },
  { code: "BDT", symbol: "৳", label: "Taka bangladais (BDT)" },
  { code: "TRY", symbol: "₺", label: "Livre turque (TRY)" },
  { code: "JPY", symbol: "¥", label: "Yen japonais (JPY)" },
  { code: "KRW", symbol: "₩", label: "Won sud-coréen (KRW)" },
  { code: "CAD", symbol: "$", label: "Dollar canadien (CAD)" }
];

export const REGIONS = [
  {
    region: "Afrique",
    countries: [
      { name: "Tanzanie", currency: "TZS", cities: ["Dar es Salaam", "Tanga", "Dodoma", "Arusha", "Mwanza", "Zanzibar"] },
      { name: "Kenya", currency: "KES", cities: ["Nairobi", "Mombasa", "Kisumu"] },
      { name: "Ouganda", currency: "UGX", cities: ["Kampala", "Entebbe"] },
      { name: "Rwanda", currency: "RWF", cities: ["Kigali"] },
      { name: "RD Congo", currency: "CDF", cities: ["Kinshasa", "Lubumbashi", "Goma"] },
      { name: "Nigeria", currency: "NGN", cities: ["Lagos", "Abuja", "Port Harcourt"] },
      { name: "Ghana", currency: "GHS", cities: ["Accra", "Kumasi"] },
      { name: "Afrique du Sud", currency: "ZAR", cities: ["Johannesburg", "Le Cap", "Pretoria", "Durban"] },
      { name: "Égypte", currency: "EGP", cities: ["Le Caire", "Alexandrie"] },
      { name: "Maroc", currency: "MAD", cities: ["Casablanca", "Rabat", "Marrakech"] },
      { name: "Sénégal", currency: "XOF", cities: ["Dakar", "Thiès"] },
      { name: "Côte d'Ivoire", currency: "XOF", cities: ["Abidjan", "Yamoussoukro"] },
      { name: "Cameroun", currency: "XAF", cities: ["Douala", "Yaoundé"] },
      { name: "Éthiopie", currency: "ETB", cities: ["Addis-Abeba"] },
      { name: "Zambie", currency: "ZMW", cities: ["Lusaka"] },
      { name: "Algérie", currency: "DZD", cities: ["Alger", "Oran"] },
      { name: "Tunisie", currency: "TND", cities: ["Tunis", "Sfax"] },
      { name: "Mozambique", currency: "MZN", cities: ["Maputo"] }
    ]
  },
  {
    region: "Asie",
    countries: [
      { name: "Inde", currency: "INR", cities: ["Mumbai", "New Delhi", "Bangalore"] },
      { name: "Chine", currency: "CNY", cities: ["Shanghai", "Pékin", "Shenzhen"] },
      { name: "Émirats Arabes Unis", currency: "AED", cities: ["Dubaï", "Abou Dabi"] },
      { name: "Arabie Saoudite", currency: "SAR", cities: ["Riyad", "Djeddah"] },
      { name: "Qatar", currency: "QAR", cities: ["Doha"] },
      { name: "Indonésie", currency: "IDR", cities: ["Jakarta", "Surabaya"] },
      { name: "Philippines", currency: "PHP", cities: ["Manille", "Cebu"] },
      { name: "Malaisie", currency: "MYR", cities: ["Kuala Lumpur"] },
      { name: "Singapour", currency: "SGD", cities: ["Singapour"] },
      { name: "Thaïlande", currency: "THB", cities: ["Bangkok"] },
      { name: "Vietnam", currency: "VND", cities: ["Hô Chi Minh-Ville", "Hanoï"] },
      { name: "Pakistan", currency: "PKR", cities: ["Karachi", "Lahore"] },
      { name: "Bangladesh", currency: "BDT", cities: ["Dacca"] },
      { name: "Turquie", currency: "TRY", cities: ["Istanbul", "Ankara"] },
      { name: "Japon", currency: "JPY", cities: ["Tokyo", "Osaka"] },
      { name: "Corée du Sud", currency: "KRW", cities: ["Séoul"] }
    ]
  },
  {
    region: "Autres régions",
    countries: [
      { name: "France", currency: "EUR", cities: ["Paris", "Lyon", "Marseille"] },
      { name: "États-Unis", currency: "USD", cities: ["New York", "Los Angeles", "Chicago"] },
      { name: "Royaume-Uni", currency: "GBP", cities: ["Londres"] },
      { name: "Canada", currency: "CAD", cities: ["Toronto", "Montréal"] }
    ]
  }
];
EOF
echo "   ✅ Créé : src/constants/countries.js"

# ---------------------------------------------------------------------------
# 2. src/constants/pricing.js — prix par défaut en USD (fallback hors-ligne)
# ---------------------------------------------------------------------------

write_file "src/constants/pricing.js"
cat > "src/constants/pricing.js" <<'EOF'
// Catalogue de services PAR DÉFAUT (prix de base en USD).
// Ces valeurs ne servent que de secours si aucun prix n'a encore été
// configuré dans Supabase (table pricing_settings). Une fois la table
// créée, modifiez les prix depuis /dashboard → "Tarifs des services" —
// plus besoin de toucher ce fichier.

export const DEFAULT_SERVICE_ITEMS = [
  {
    id: "site-vitrine",
    label: "Site vitrine professionnel (jusqu'à 5 pages)",
    price: 250,
    unit: "one-time"
  },
  {
    id: "boutique",
    label: "Boutique en ligne / e-commerce",
    price: 600,
    unit: "one-time"
  },
  {
    id: "reservation",
    label: "Système de réservation en ligne (hôtels, cliniques)",
    price: 220,
    unit: "one-time"
  },
  {
    id: "refonte-audit",
    label: "Audit technique + corrections d'un site existant",
    price: 150,
    unit: "one-time"
  },
  {
    id: "seo-local",
    label: "Référencement local (SEO) — 1 mois",
    price: 90,
    unit: "monthly"
  },
  {
    id: "multilingue",
    label: "Version multilingue (FR / EN / SW / AR...)",
    price: 80,
    unit: "one-time"
  },
  {
    id: "maintenance",
    label: "Maintenance & mises à jour mensuelles",
    price: 50,
    unit: "monthly"
  },
  {
    id: "urgent",
    label: "Livraison express (sous 7 jours)",
    price: 0,
    unit: "surcharge",
    surchargeRate: 0.2
  }
];
EOF
echo "   ✅ Mis à jour : src/constants/pricing.js (prix en USD)"

# ---------------------------------------------------------------------------
# 3. src/utils/formatCurrency.js — formatage multi-devises
# ---------------------------------------------------------------------------

write_file "src/utils/formatCurrency.js"
cat > "src/utils/formatCurrency.js" <<'EOF'
import { CURRENCIES } from "../constants/countries";

function symbolFor(code) {
  const match = CURRENCIES.find((c) => c.code === code);
  return match ? match.symbol : code;
}

export function formatAmount(amount, currencyCode = "USD") {
  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: currencyCode,
      maximumFractionDigits: amount >= 1000 ? 0 : 2
    }).format(amount);
  } catch (err) {
    const formatted = new Intl.NumberFormat("en-US", {
      maximumFractionDigits: 0
    }).format(Math.round(amount));
    return `${formatted} ${symbolFor(currencyCode)}`;
  }
}

// Conservée pour compatibilité si d'anciens fichiers l'importent encore.
export function formatTZS(amount) {
  return formatAmount(amount, "TZS");
}
EOF
echo "   ✅ Mis à jour : src/utils/formatCurrency.js"

# ---------------------------------------------------------------------------
# 4. src/services/exchangeRates.js — taux de change en direct (gratuit, sans clé)
# ---------------------------------------------------------------------------

write_file "src/services/exchangeRates.js"
cat > "src/services/exchangeRates.js" <<'EOF'
// Récupère les taux de change USD -> devises via une API publique gratuite
// (open.er-api.com, pas de clé requise). Les taux sont mis en cache
// pendant 6h dans sessionStorage pour limiter les appels réseau.

const CACHE_KEY = "assani_exchange_rates_usd_v1";
const CACHE_TTL_MS = 6 * 60 * 60 * 1000; // 6 heures

export async function getUsdExchangeRates() {
  try {
    const cached = sessionStorage.getItem(CACHE_KEY);
    if (cached) {
      const parsed = JSON.parse(cached);
      if (Date.now() - parsed.timestamp < CACHE_TTL_MS) {
        return parsed.rates;
      }
    }
  } catch (err) {
    // stockage indisponible : on ignore simplement le cache
  }

  const response = await fetch("https://open.er-api.com/v6/latest/USD");
  if (!response.ok) throw new Error("EXCHANGE_RATE_FAILED");

  const data = await response.json();
  if (data.result !== "success" || !data.rates) {
    throw new Error("EXCHANGE_RATE_FAILED");
  }

  try {
    sessionStorage.setItem(
      CACHE_KEY,
      JSON.stringify({ rates: data.rates, timestamp: Date.now() })
    );
  } catch (err) {
    // ignore
  }

  return data.rates;
}

export function convertFromUsd(amountUsd, rates, currencyCode) {
  const rate = rates?.[currencyCode];
  if (!rate) return amountUsd;
  return amountUsd * rate;
}
EOF
echo "   ✅ Créé : src/services/exchangeRates.js"

# ---------------------------------------------------------------------------
# 5. src/services/pricingStore.js — lecture/écriture des tarifs (Supabase)
# ---------------------------------------------------------------------------

write_file "src/services/pricingStore.js"
cat > "src/services/pricingStore.js" <<'EOF'
import { supabase } from "./supabase";
import { DEFAULT_SERVICE_ITEMS } from "../constants/pricing";

// Lit les tarifs configurés dans Supabase. Si la table n'existe pas
// encore, ou est vide, ou si la requête échoue (hors-ligne...), on
// retombe silencieusement sur les prix par défaut du code.
export async function fetchServicePrices() {
  try {
    const { data, error } = await supabase
      .from("pricing_settings")
      .select("*")
      .order("sort_order", { ascending: true });

    if (error || !data || data.length === 0) {
      return DEFAULT_SERVICE_ITEMS;
    }

    return data.map((row) => ({
      id: row.id,
      label: row.label,
      price: Number(row.price_usd),
      unit: row.unit,
      surchargeRate:
        row.surcharge_rate !== null && row.surcharge_rate !== undefined
          ? Number(row.surcharge_rate)
          : undefined
    }));
  } catch (err) {
    return DEFAULT_SERVICE_ITEMS;
  }
}

// Remplace entièrement la liste de tarifs par celle fournie (utilisé par
// l'écran d'administration "Tarifs des services").
export async function saveServicePrices(items) {
  const ids = items.map((item) => item.id);

  const { data: existing } = await supabase.from("pricing_settings").select("id");
  const existingIds = (existing || []).map((row) => row.id);
  const toDelete = existingIds.filter((id) => !ids.includes(id));

  if (toDelete.length > 0) {
    await supabase.from("pricing_settings").delete().in("id", toDelete);
  }

  const rows = items.map((item, index) => ({
    id: item.id,
    label: item.label,
    price_usd: item.price,
    unit: item.unit,
    surcharge_rate: item.unit === "surcharge" ? item.surchargeRate ?? 0 : null,
    sort_order: index,
    updated_at: new Date().toISOString()
  }));

  const { error } = await supabase.from("pricing_settings").upsert(rows);
  if (error) throw error;
}
EOF
echo "   ✅ Créé : src/services/pricingStore.js"

# ---------------------------------------------------------------------------
# 6. supabase/pricing_settings.sql — table + policies à exécuter une fois
# ---------------------------------------------------------------------------

write_file "supabase/pricing_settings.sql"
cat > "supabase/pricing_settings.sql" <<'EOF'
-- =====================================================================
-- Table "pricing_settings" — tarifs des services affichés sur
-- /devis-instantane, modifiables depuis le dashboard (/dashboard).
--
-- À exécuter une seule fois dans : Supabase → SQL Editor → New query
-- =====================================================================

create table if not exists public.pricing_settings (
  id text primary key,
  label text not null,
  price_usd numeric not null default 0,
  unit text not null default 'one-time',
  surcharge_rate numeric,
  sort_order integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.pricing_settings enable row level security;

-- Le calculateur de devis public doit pouvoir lire les tarifs.
drop policy if exists "Public can read pricing" on public.pricing_settings;
create policy "Public can read pricing"
  on public.pricing_settings
  for select
  to anon, authenticated
  using (true);

-- Seul un utilisateur connecté (vous, depuis /admin) peut modifier les tarifs.
drop policy if exists "Only authenticated users can insert pricing" on public.pricing_settings;
create policy "Only authenticated users can insert pricing"
  on public.pricing_settings
  for insert
  to authenticated
  with check (true);

drop policy if exists "Only authenticated users can update pricing" on public.pricing_settings;
create policy "Only authenticated users can update pricing"
  on public.pricing_settings
  for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Only authenticated users can delete pricing" on public.pricing_settings;
create policy "Only authenticated users can delete pricing"
  on public.pricing_settings
  for delete
  to authenticated
  using (true);

-- Prix de départ (identiques à src/constants/pricing.js). Vous pourrez
-- tout modifier ensuite depuis le dashboard.
insert into public.pricing_settings (id, label, price_usd, unit, surcharge_rate, sort_order)
values
  ('site-vitrine', 'Site vitrine professionnel (jusqu''à 5 pages)', 250, 'one-time', null, 0),
  ('boutique', 'Boutique en ligne / e-commerce', 600, 'one-time', null, 1),
  ('reservation', 'Système de réservation en ligne (hôtels, cliniques)', 220, 'one-time', null, 2),
  ('refonte-audit', 'Audit technique + corrections d''un site existant', 150, 'one-time', null, 3),
  ('seo-local', 'Référencement local (SEO) — 1 mois', 90, 'monthly', null, 4),
  ('multilingue', 'Version multilingue (FR / EN / SW / AR...)', 80, 'one-time', null, 5),
  ('maintenance', 'Maintenance & mises à jour mensuelles', 50, 'monthly', null, 6),
  ('urgent', 'Livraison express (sous 7 jours)', 0, 'surcharge', 0.2, 7)
on conflict (id) do nothing;
EOF
echo "   ✅ Créé : supabase/pricing_settings.sql (à exécuter dans Supabase SQL Editor)"

# ---------------------------------------------------------------------------
# 7. src/dashboard/PricingManager.jsx — édition des tarifs depuis le dashboard
# ---------------------------------------------------------------------------

write_file "src/dashboard/PricingManager.jsx"
cat > "src/dashboard/PricingManager.jsx" <<'EOF'
import { useEffect, useState } from "react";
import { toast } from "react-toastify";
import { Plus, Trash2, Save, Loader2, DollarSign } from "lucide-react";

import { fetchServicePrices, saveServicePrices } from "../services/pricingStore";
import { logger } from "../services/logger";

const UNIT_OPTIONS = [
  { value: "one-time", label: "Paiement unique" },
  { value: "monthly", label: "Mensuel" },
  { value: "surcharge", label: "Supplément (%)" }
];

function newId(label) {
  const slug = label
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
  return `${slug || "service"}-${Date.now()}`;
}

export default function PricingManager() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    (async () => {
      const prices = await fetchServicePrices();
      setItems(prices);
      setLoading(false);
    })();
  }, []);

  const updateItem = (id, field, value) => {
    setItems((prev) =>
      prev.map((item) => (item.id === id ? { ...item, [field]: value } : item))
    );
  };

  const removeItem = (id) => {
    setItems((prev) => prev.filter((item) => item.id !== id));
  };

  const addItem = () => {
    const label = "Nouveau service";
    setItems((prev) => [...prev, { id: newId(label), label, price: 0, unit: "one-time" }]);
  };

  const save = async () => {
    setSaving(true);
    try {
      await saveServicePrices(items);
      toast.success("Tarifs mis à jour. Le calculateur public utilise déjà ces nouveaux prix.");
    } catch (err) {
      logger.error("Failed to save pricing", err);
      toast.error(
        "Impossible d'enregistrer. Avez-vous exécuté supabase/pricing_settings.sql dans Supabase ?"
      );
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="glass pricing-manager">
        <Loader2 className="spin" size={20} />
      </div>
    );
  }

  return (
    <div className="glass pricing-manager">
      <div className="pricing-manager-header">
        <h2>
          <DollarSign size={18} />
          Tarifs des services (en USD)
        </h2>
        <p>
          Ces prix de base en dollars alimentent le calculateur public
          (/devis-instantane). Ils sont convertis automatiquement dans la
          devise choisie par chaque visiteur, où qu'il se trouve dans le monde.
        </p>
      </div>

      <div className="pricing-manager-list">
        {items.map((item) => (
          <div className="pricing-manager-row" key={item.id}>
            <input
              type="text"
              value={item.label}
              onChange={(e) => updateItem(item.id, "label", e.target.value)}
              placeholder="Nom du service"
            />

            {item.unit === "surcharge" ? (
              <input
                type="number"
                min="0"
                max="100"
                value={Math.round((item.surchargeRate || 0) * 100)}
                onChange={(e) =>
                  updateItem(item.id, "surchargeRate", Number(e.target.value) / 100)
                }
                title="Pourcentage de supplément"
              />
            ) : (
              <input
                type="number"
                min="0"
                step="1"
                value={item.price}
                onChange={(e) => updateItem(item.id, "price", Number(e.target.value))}
                title="Prix en USD"
              />
            )}

            <select
              value={item.unit}
              onChange={(e) => updateItem(item.id, "unit", e.target.value)}
            >
              {UNIT_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>

            <button
              type="button"
              className="danger-btn"
              onClick={() => removeItem(item.id)}
              aria-label="Supprimer ce service"
            >
              <Trash2 size={14} />
            </button>
          </div>
        ))}
      </div>

      <div className="pricing-manager-actions">
        <button type="button" className="ghost-btn" onClick={addItem}>
          <Plus size={16} />
          Ajouter un service
        </button>

        <button type="button" className="premium-cta-btn" onClick={save} disabled={saving}>
          {saving ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
          Enregistrer les tarifs
        </button>
      </div>
    </div>
  );
}
EOF
echo "   ✅ Créé : src/dashboard/PricingManager.jsx"

# ---------------------------------------------------------------------------
# 8. src/components/pricing/PricingCalculator.jsx — global, multi-devises
# ---------------------------------------------------------------------------

write_file "src/components/pricing/PricingCalculator.jsx"
cat > "src/components/pricing/PricingCalculator.jsx" <<'EOF'
import { useEffect, useMemo, useState } from "react";
import { motion } from "framer-motion";
import { MessageCircle, Loader2, Info, Check } from "lucide-react";

import { REGIONS, CURRENCIES, OTHER_COUNTRY } from "../../constants/countries";
import { fetchServicePrices } from "../../services/pricingStore";
import { getUsdExchangeRates, convertFromUsd } from "../../services/exchangeRates";
import { formatAmount } from "../../utils/formatCurrency";
import { buildWhatsAppLink } from "../../config/contact";
import { logger } from "../../services/logger";

const ALL_COUNTRIES = REGIONS.flatMap((region) =>
  region.countries.map((country) => ({ ...country, region: region.region }))
);

function findCountry(name) {
  return ALL_COUNTRIES.find((country) => country.name === name);
}

export default function PricingCalculator() {
  const [items, setItems] = useState([]);
  const [itemsLoading, setItemsLoading] = useState(true);

  const [rates, setRates] = useState(null);
  const [ratesLoading, setRatesLoading] = useState(true);

  const defaultCountry = ALL_COUNTRIES[0];
  const [countryName, setCountryName] = useState(defaultCountry.name);
  const [city, setCity] = useState(defaultCountry.cities[0] || "");
  const [customCountry, setCustomCountry] = useState("");
  const [currency, setCurrency] = useState(defaultCountry.currency);

  const [selected, setSelected] = useState([]);

  useEffect(() => {
    (async () => {
      const prices = await fetchServicePrices();
      setItems(prices);
      setItemsLoading(false);
    })();
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const liveRates = await getUsdExchangeRates();
        setRates(liveRates);
      } catch (err) {
        logger.error("Exchange rate fetch failed", err);
        setRates(null);
      } finally {
        setRatesLoading(false);
      }
    })();
  }, []);

  const isOther = countryName === OTHER_COUNTRY;
  const selectedCountry = findCountry(countryName);
  const cityOptions = selectedCountry?.cities || [];

  const handleCountryChange = (name) => {
    setCountryName(name);
    if (name === OTHER_COUNTRY) {
      setCity("");
      return;
    }
    const country = findCountry(name);
    if (country) {
      setCurrency(country.currency);
      setCity(country.cities[0] || "");
    }
  };

  const toggleItem = (id) => {
    setSelected((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const convert = (amountUsd) => {
    if (currency === "USD" || !rates) return amountUsd;
    return convertFromUsd(amountUsd, rates, currency);
  };

  const { subtotal, surcharge, total, chosenItems } = useMemo(() => {
    const chosen = items.filter((item) => selected.includes(item.id));
    const base = chosen
      .filter((item) => item.unit !== "surcharge")
      .reduce((sum, item) => sum + item.price, 0);

    const urgent = chosen.find((item) => item.unit === "surcharge");
    const extra = urgent ? Math.round(base * (urgent.surchargeRate || 0)) : 0;

    return {
      subtotal: base,
      surcharge: extra,
      total: base + extra,
      chosenItems: chosen
    };
  }, [items, selected]);

  const locationLabel = isOther
    ? customCountry.trim() || "ma région"
    : `${city ? `${city}, ` : ""}${countryName}`;

  const whatsappMessage = [
    `Bonjour Assani, je souhaite un devis pour un projet à ${locationLabel}.`,
    "",
    "Services sélectionnés :",
    ...chosenItems.map((item) => {
      const priceLabel =
        item.unit === "surcharge"
          ? `urgence, +${Math.round((item.surchargeRate || 0) * 100)}%`
          : formatAmount(convert(item.price), currency);
      return `- ${item.label} (${priceLabel})`;
    }),
    "",
    `Estimation totale : ${formatAmount(convert(total), currency)}${
      chosenItems.some((i) => i.unit === "monthly") ? " (+ frais mensuels selon options)" : ""
    }`,
    "",
    "Pouvez-vous confirmer les délais et les modalités de paiement ?"
  ].join("\n");

  if (itemsLoading) {
    return (
      <div className="pricing-calculator glass">
        <Loader2 className="spin" size={22} />
      </div>
    );
  }

  return (
    <div className="pricing-calculator glass">
      <div className="pricing-location-grid">
        <div className="pricing-field">
          <label htmlFor="devis-country">Pays</label>
          <select
            id="devis-country"
            value={countryName}
            onChange={(e) => handleCountryChange(e.target.value)}
          >
            {REGIONS.map((region) => (
              <optgroup label={region.region} key={region.region}>
                {region.countries.map((country) => (
                  <option key={country.name} value={country.name}>
                    {country.name}
                  </option>
                ))}
              </optgroup>
            ))}
            <option value={OTHER_COUNTRY}>Autre pays / partout ailleurs</option>
          </select>
        </div>

        <div className="pricing-field">
          <label htmlFor="devis-city">Ville</label>
          {isOther || cityOptions.length === 0 ? (
            <input
              id="devis-city"
              type="text"
              placeholder="Votre pays et ville"
              value={isOther ? customCountry : city}
              onChange={(e) =>
                isOther ? setCustomCountry(e.target.value) : setCity(e.target.value)
              }
            />
          ) : (
            <select id="devis-city" value={city} onChange={(e) => setCity(e.target.value)}>
              {cityOptions.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          )}
        </div>

        <div className="pricing-field">
          <label htmlFor="devis-currency">Devise</label>
          <select
            id="devis-currency"
            value={currency}
            onChange={(e) => setCurrency(e.target.value)}
          >
            {CURRENCIES.map((c) => (
              <option key={c.code} value={c.code}>
                {c.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      {!ratesLoading && !rates && currency !== "USD" && (
        <p className="pricing-rate-note">
          <Info size={14} />
          Taux de change indisponible pour le moment — montants affichés en USD.
        </p>
      )}

      <ul className="pricing-items">
        {items.map((item) => {
          const active = selected.includes(item.id);
          return (
            <li key={item.id}>
              <button
                type="button"
                className={`pricing-item-btn ${active ? "active" : ""}`}
                onClick={() => toggleItem(item.id)}
              >
                <span className="pricing-item-check">{active && <Check size={14} />}</span>
                <span className="pricing-item-label">{item.label}</span>
                <span className="pricing-item-price">
                  {item.unit === "surcharge"
                    ? `+${Math.round((item.surchargeRate || 0) * 100)}%`
                    : formatAmount(convert(item.price), currency) +
                      (item.unit === "monthly" ? " /mois" : "")}
                </span>
              </button>
            </li>
          );
        })}
      </ul>

      <motion.div className="pricing-summary" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
        <div className="pricing-summary-row">
          <span>Sous-total</span>
          <span>{formatAmount(convert(subtotal), currency)}</span>
        </div>

        {surcharge > 0 && (
          <div className="pricing-summary-row">
            <span>Supplément urgence</span>
            <span>{formatAmount(convert(surcharge), currency)}</span>
          </div>
        )}

        <div className="pricing-summary-row pricing-total">
          <span>Estimation totale</span>
          <span>{formatAmount(convert(total), currency)}</span>
        </div>

        <a
          href={buildWhatsAppLink(whatsappMessage)}
          target="_blank"
          rel="noreferrer"
          className={`premium-cta-btn ${chosenItems.length === 0 ? "disabled-link" : ""}`}
          onClick={(e) => {
            if (chosenItems.length === 0) e.preventDefault();
          }}
        >
          <MessageCircle size={16} />
          Recevoir ce devis sur WhatsApp
        </a>

        <p className="pricing-disclaimer">
          Estimation indicative convertie automatiquement depuis un prix de
          base en USD. Le prix final dépend de la complexité exacte du
          projet et sera confirmé après un court échange.
        </p>
      </motion.div>
    </div>
  );
}
EOF
echo "   ✅ Mis à jour : src/components/pricing/PricingCalculator.jsx (global, multi-devises)"

# ---------------------------------------------------------------------------
# 9. src/services/pagespeed.js — cache local pour économiser le quota
# ---------------------------------------------------------------------------

write_file "src/services/pagespeed.js"
cat > "src/services/pagespeed.js" <<'EOF'
// Client léger pour l'API publique Google PageSpeed Insights v5.
// Sans clé API, le quota gratuit partagé est très limité (d'où les
// erreurs "Trop de demandes"). Définissez VITE_PAGESPEED_API_KEY dans
// un fichier .env pour obtenir un quota personnel généreux — voir les
// instructions affichées sur la page /audit-instantane.

const PSI_ENDPOINT = "https://www.googleapis.com/pagespeedonline/v5/runPagespeed";

const CATEGORIES = ["performance", "seo", "accessibility", "best-practices"];

const KEY_AUDITS = [
  "viewport",
  "document-title",
  "meta-description",
  "is-on-https",
  "largest-contentful-paint",
  "uses-responsive-images",
  "tap-targets",
  "font-display",
  "image-alt",
  "link-text"
];

const CACHE_TTL_MS = 30 * 60 * 1000; // 30 minutes

function normalizeUrl(raw) {
  let value = raw.trim();
  if (!/^https?:\/\//i.test(value)) {
    value = `https://${value}`;
  }
  return value;
}

function cacheKey(url, strategy) {
  return `assani_psi_cache_${strategy}_${url}`;
}

function readCache(url, strategy) {
  try {
    const raw = sessionStorage.getItem(cacheKey(url, strategy));
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (Date.now() - parsed.timestamp > CACHE_TTL_MS) return null;
    return parsed.data;
  } catch (err) {
    return null;
  }
}

function writeCache(url, strategy, data) {
  try {
    sessionStorage.setItem(
      cacheKey(url, strategy),
      JSON.stringify({ data, timestamp: Date.now() })
    );
  } catch (err) {
    // stockage indisponible : on ignore simplement le cache
  }
}

export async function runPageSpeedAudit(rawUrl, { strategy = "mobile" } = {}) {
  const url = normalizeUrl(rawUrl);

  const cached = readCache(url, strategy);
  if (cached) return cached;

  const params = new URLSearchParams();
  params.set("url", url);
  params.set("strategy", strategy);
  CATEGORIES.forEach((category) => params.append("category", category));

  const apiKey = import.meta.env?.VITE_PAGESPEED_API_KEY;
  if (apiKey) params.set("key", apiKey);

  const response = await fetch(`${PSI_ENDPOINT}?${params.toString()}`);

  if (!response.ok) {
    if (response.status === 429) {
      throw new Error("QUOTA_EXCEEDED");
    }
    throw new Error("REQUEST_FAILED");
  }

  const data = await response.json();
  const categories = data?.lighthouseResult?.categories || {};
  const audits = data?.lighthouseResult?.audits || {};

  const scores = {
    performance: categories.performance?.score ?? null,
    seo: categories.seo?.score ?? null,
    accessibility: categories.accessibility?.score ?? null,
    bestPractices: categories["best-practices"]?.score ?? null
  };

  const issues = KEY_AUDITS.map((id) => audits[id])
    .filter((audit) => audit && typeof audit.score === "number" && audit.score < 0.9)
    .map((audit) => ({
      title: audit.title,
      description: audit.description ? audit.description.split(". ")[0] : ""
    }))
    .slice(0, 5);

  const result = { url, strategy, scores, issues };
  writeCache(url, strategy, result);
  return result;
}
EOF
echo "   ✅ Mis à jour : src/services/pagespeed.js (mise en cache 30 min)"

# ---------------------------------------------------------------------------
# 10. src/components/audit/LiveAudit.jsx — correctif mobile + aide clé API
# ---------------------------------------------------------------------------

write_file "src/components/audit/LiveAudit.jsx"
cat > "src/components/audit/LiveAudit.jsx" <<'EOF'
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Gauge,
  Search,
  ShieldCheck,
  Eye,
  Loader2,
  AlertTriangle,
  MessageCircle,
  RefreshCcw,
  KeyRound,
  ExternalLink
} from "lucide-react";

import { runPageSpeedAudit } from "../../services/pagespeed";
import { buildWhatsAppLink } from "../../config/contact";
import { logger } from "../../services/logger";

const SCORE_METRICS = [
  { key: "performance", label: "Performance", Icon: Gauge },
  { key: "seo", label: "SEO", Icon: Search },
  { key: "accessibility", label: "Accessibilité", Icon: Eye },
  { key: "bestPractices", label: "Bonnes pratiques", Icon: ShieldCheck }
];

function scoreColor(score) {
  if (score === null || score === undefined) return "var(--muted)";
  if (score >= 0.9) return "#22c55e";
  if (score >= 0.5) return "#f59e0b";
  return "#ef4444";
}

const hasApiKey = Boolean(import.meta.env?.VITE_PAGESPEED_API_KEY);

export default function LiveAudit() {
  const [url, setUrl] = useState("");
  const [strategy, setStrategy] = useState("mobile");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [showHelp, setShowHelp] = useState(!hasApiKey);

  const launchAudit = async (e) => {
    e.preventDefault();

    if (url.trim().length < 4) {
      setError("Merci de saisir une adresse de site valide.");
      return;
    }

    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const audit = await runPageSpeedAudit(url, { strategy });
      setResult(audit);
    } catch (err) {
      logger.error("Live audit failed", err);
      if (err.message === "QUOTA_EXCEEDED") {
        setError(
          hasApiKey
            ? "Trop de demandes en ce moment, même avec votre clé API. Réessayez dans quelques minutes."
            : "Le quota gratuit sans clé API est très limité et vite épuisé. Ajoutez une clé API gratuite (instructions ci-dessous) pour analyser sans limite, ou contactez-moi directement sur WhatsApp."
        );
        setShowHelp(true);
      } else {
        setError(
          "Impossible d'analyser ce site pour le moment. Vérifiez l'adresse (ex: monsite.com) ou contactez-moi directement."
        );
      }
    } finally {
      setLoading(false);
    }
  };

  const whatsappMessage = result
    ? [
        `Bonjour Assani, je viens de tester mon site (${result.url}) avec votre outil d'audit.`,
        "",
        "Scores obtenus :",
        ...SCORE_METRICS.map(({ key, label }) => {
          const score = result.scores[key];
          return `- ${label} : ${score !== null ? Math.round(score * 100) : "N/A"}/100`;
        }),
        "",
        result.issues.length
          ? `Problèmes détectés : ${result.issues.map((issue) => issue.title).join(", ")}`
          : "Je souhaite en savoir plus sur les améliorations possibles.",
        "",
        "Pouvez-vous me proposer une solution ?"
      ].join("\n")
    : "";

  return (
    <div className="live-audit glass">
      <form className="live-audit-form" onSubmit={launchAudit}>
        <input
          type="text"
          placeholder="ex: monhotel.co.tz"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
        />

        <select value={strategy} onChange={(e) => setStrategy(e.target.value)}>
          <option value="mobile">Mobile</option>
          <option value="desktop">Ordinateur</option>
        </select>

        <button type="submit" disabled={loading} className="premium-cta-btn">
          {loading ? <Loader2 className="spin" size={18} /> : "Analyser mon site"}
        </button>
      </form>

      {error && (
        <div className="live-audit-error">
          <AlertTriangle size={16} />
          <span>{error}</span>
        </div>
      )}

      <div className="audit-help">
        <button
          type="button"
          className="audit-help-toggle"
          onClick={() => setShowHelp((prev) => !prev)}
        >
          <KeyRound size={14} />
          {hasApiKey
            ? "Clé API PageSpeed détectée ✓"
            : "Aucune clé API configurée — comment en obtenir une gratuitement ?"}
        </button>

        {showHelp && !hasApiKey && (
          <ol className="audit-help-steps">
            <li>
              Allez sur{" "}
              <a
                href="https://console.cloud.google.com/apis/library/pagespeedonline.googleapis.com"
                target="_blank"
                rel="noreferrer"
              >
                Google Cloud Console <ExternalLink size={12} />
              </a>{" "}
              et connectez-vous avec un compte Google (créez-en un si besoin, c'est gratuit).
            </li>
            <li>Cliquez sur le bouton "Activer" pour l'API "PageSpeed Insights".</li>
            <li>
              Dans le menu de gauche, allez sur "Identifiants" → "Créer des identifiants" →
              "Clé API". Copiez la clé générée (une suite de lettres/chiffres).
            </li>
            <li>
              À la racine de votre projet, créez un fichier nommé <code>.env</code> (s'il
              n'existe pas déjà) et ajoutez cette ligne :
              <br />
              <code>VITE_PAGESPEED_API_KEY=collez_votre_cle_ici</code>
            </li>
            <li>
              Relancez <code>npm run dev</code> (ou redéployez le site en production) pour que
              la clé soit prise en compte.
            </li>
          </ol>
        )}
      </div>

      <AnimatePresence>
        {result && (
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            className="live-audit-results"
          >
            <div className="score-grid">
              {SCORE_METRICS.map(({ key, label, Icon }) => {
                const score = result.scores[key];
                const pct = score !== null && score !== undefined ? Math.round(score * 100) : null;
                return (
                  <div className="score-ring-card" key={key}>
                    <div
                      className="score-ring"
                      style={{
                        background: `conic-gradient(${scoreColor(score)} ${pct ?? 0}%, var(--card-bg) 0)`
                      }}
                    >
                      <span>{pct !== null ? pct : "–"}</span>
                    </div>
                    <div className="score-ring-label">
                      <Icon size={16} />
                      {label}
                    </div>
                  </div>
                );
              })}
            </div>

            {result.issues.length > 0 && (
              <div className="live-audit-issues">
                <h4>Points à corriger en priorité</h4>
                <ul>
                  {result.issues.map((issue) => (
                    <li key={issue.title}>
                      <strong>{issue.title}</strong>
                      {issue.description && <p>{issue.description}</p>}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <div className="live-audit-cta">
              <a
                href={buildWhatsAppLink(whatsappMessage)}
                target="_blank"
                rel="noreferrer"
                className="premium-cta-btn"
              >
                <MessageCircle size={16} />
                Recevoir mon plan d'action sur WhatsApp
              </a>

              <button
                type="button"
                className="ghost-btn"
                onClick={() => {
                  setResult(null);
                  setUrl("");
                }}
              >
                <RefreshCcw size={16} />
                Analyser un autre site
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
EOF
echo "   ✅ Mis à jour : src/components/audit/LiveAudit.jsx (bug mobile corrigé + aide clé API)"

# ---------------------------------------------------------------------------
# 11. src/styles/premium.css — réécriture complète (corrige le bug mobile)
# ---------------------------------------------------------------------------

write_file "src/styles/premium.css"
cat > "src/styles/premium.css" <<'EOF'
/* ============ FONCTIONNALITÉS PREMIUM (v2) ============ */

.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Bouton premium dédié : contrairement à .nav-cta-btn (masqué sous 900px
   dans la navbar), celui-ci reste TOUJOURS visible, y compris en mode
   portrait sur mobile. C'est le correctif du bouton "Analyser" invisible. */
.premium-cta-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.85rem 1.4rem;
  border-radius: 999px;
  border: none;
  background: var(--gradient);
  color: #ffffff;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: transform 0.2s ease, box-shadow 0.2s ease, opacity 0.2s ease;
}

.premium-cta-btn:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow);
}

.premium-cta-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.ghost-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  background: transparent;
  border: 1px solid var(--glass-border);
  color: var(--text);
  padding: 0.6rem 1.2rem;
  border-radius: 999px;
  cursor: pointer;
  transition: border-color 0.2s ease, color 0.2s ease;
}

.ghost-btn:hover {
  border-color: var(--primary);
  color: var(--primary);
}

.disabled-link {
  opacity: 0.5;
  pointer-events: none;
}

.nav-cta-btn-ghost {
  padding: 0.6rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

/* Corrige aussi le bouton "Demander un service" du menu mobile, qui
   disparaissait pour la même raison (règle .nav-cta-btn { display:none }
   sous 900px, présente dans le CSS d'origine). */
@media (max-width: 900px) {
  .mobile-menu .nav-cta-btn {
    display: flex;
  }
}

/* Audit instantané */

.live-audit {
  padding: 2rem;
  border-radius: 20px;
  margin: 2rem 0;
}

.live-audit-form {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.live-audit-form input,
.live-audit-form select {
  flex: 1;
  min-width: 200px;
  padding: 0.85rem 1rem;
  border-radius: 12px;
  border: 1px solid var(--glass-border);
  background: var(--card-bg);
  color: var(--text);
}

.live-audit-form .premium-cta-btn {
  flex: 1;
  min-width: 200px;
}

@media (max-width: 560px) {
  .live-audit-form {
    flex-direction: column;
  }

  .live-audit-form input,
  .live-audit-form select,
  .live-audit-form .premium-cta-btn {
    width: 100%;
    min-width: 0;
  }
}

.live-audit-error {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  margin-top: 1rem;
  color: #f59e0b;
  font-size: 0.9rem;
}

.audit-help {
  margin-top: 1.25rem;
  border-top: 1px dashed var(--glass-border);
  padding-top: 1rem;
}

.audit-help-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  background: none;
  border: none;
  color: var(--primary);
  cursor: pointer;
  font-size: 0.85rem;
  padding: 0;
}

.audit-help-steps {
  margin-top: 1rem;
  padding-left: 1.2rem;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  color: var(--muted);
  font-size: 0.85rem;
}

.audit-help-steps a {
  color: var(--primary);
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.audit-help-steps code {
  background: var(--card-bg);
  border: 1px solid var(--glass-border);
  border-radius: 6px;
  padding: 0.15rem 0.4rem;
  font-size: 0.8rem;
  display: inline-block;
  margin-top: 0.2rem;
}

.live-audit-results {
  margin-top: 2rem;
}

.score-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.score-ring-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.6rem;
}

.score-ring {
  width: 88px;
  height: 88px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.3rem;
  font-weight: 700;
  color: var(--text);
  position: relative;
}

.score-ring::before {
  content: "";
  position: absolute;
  inset: 8px;
  border-radius: 50%;
  background: var(--bg-secondary);
}

.score-ring span {
  position: relative;
  z-index: 1;
}

.score-ring-label {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.85rem;
  color: var(--muted);
}

.live-audit-issues h4 {
  margin-bottom: 0.75rem;
}

.live-audit-issues ul {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
  margin-bottom: 1.5rem;
  padding: 0;
}

.live-audit-issues li {
  padding: 0.9rem 1.1rem;
  border-radius: 12px;
  background: var(--card-bg);
  border: 1px solid var(--glass-border);
}

.live-audit-issues li p {
  margin-top: 0.3rem;
  color: var(--muted);
  font-size: 0.85rem;
}

.live-audit-cta {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: center;
}

@media (max-width: 560px) {
  .live-audit-cta {
    flex-direction: column;
    align-items: stretch;
  }

  .live-audit-cta .premium-cta-btn,
  .live-audit-cta .ghost-btn {
    width: 100%;
    justify-content: center;
  }
}

/* Devis instantané */

.pricing-calculator {
  padding: 2rem;
  border-radius: 20px;
  margin: 2rem 0;
}

.pricing-location-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.pricing-field label {
  display: block;
  font-size: 0.8rem;
  color: var(--muted);
  margin-bottom: 0.4rem;
}

.pricing-field select,
.pricing-field input {
  width: 100%;
  padding: 0.65rem 0.9rem;
  border-radius: 10px;
  border: 1px solid var(--glass-border);
  background: var(--card-bg);
  color: var(--text);
}

.pricing-rate-note {
  font-size: 0.75rem;
  color: var(--muted);
  margin: -0.75rem 0 1.5rem;
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.pricing-items {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 2rem;
  padding: 0;
}

.pricing-item-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 0.9rem;
  padding: 0.9rem 1.1rem;
  border-radius: 14px;
  border: 1px solid var(--glass-border);
  background: var(--card-bg);
  color: var(--text);
  cursor: pointer;
  text-align: left;
  transition: border-color 0.2s ease, background 0.2s ease;
}

.pricing-item-btn.active {
  border-color: var(--primary);
  background: rgba(0, 212, 255, 0.08);
}

.pricing-item-check {
  width: 20px;
  height: 20px;
  border-radius: 6px;
  border: 1px solid var(--glass-border);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: var(--primary);
}

.pricing-item-label {
  flex: 1;
}

.pricing-item-price {
  font-weight: 600;
  color: var(--primary);
  white-space: nowrap;
}

.pricing-summary {
  border-top: 1px solid var(--glass-border);
  padding-top: 1.5rem;
}

.pricing-summary-row {
  display: flex;
  justify-content: space-between;
  padding: 0.4rem 0;
  color: var(--muted);
}

.pricing-total {
  color: var(--text);
  font-size: 1.2rem;
  font-weight: 700;
  border-top: 1px solid var(--glass-border);
  margin-top: 0.5rem;
  padding-top: 0.9rem;
}

.pricing-disclaimer {
  margin-top: 1rem;
  font-size: 0.8rem;
  color: var(--muted);
}

.pricing-summary .premium-cta-btn {
  width: 100%;
  margin-top: 1rem;
}

/* Bandeau de confiance partagé */

.audit-trust {
  display: flex;
  flex-wrap: wrap;
  gap: 2rem;
  justify-content: center;
  margin-top: 1.5rem;
  color: var(--muted);
  font-size: 0.9rem;
}

.audit-trust > div {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

/* Bouton devis PDF (dashboard) */

.quote-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.5rem 0.9rem;
  border-radius: 10px;
  border: 1px solid var(--glass-border);
  background: var(--card-bg);
  color: var(--text);
  cursor: pointer;
  font-size: 0.85rem;
}

.quote-btn:hover {
  border-color: var(--primary);
  color: var(--primary);
}

/* Gestion des tarifs (dashboard) */

.pricing-manager {
  padding: 2rem;
  border-radius: 20px;
  margin: 2rem 0;
}

.pricing-manager-header h2 {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.pricing-manager-header p {
  color: var(--muted);
  font-size: 0.85rem;
  margin-bottom: 1.5rem;
}

.pricing-manager-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.pricing-manager-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr auto;
  gap: 0.6rem;
  align-items: center;
}

.pricing-manager-row input,
.pricing-manager-row select {
  padding: 0.6rem 0.8rem;
  border-radius: 10px;
  border: 1px solid var(--glass-border);
  background: var(--card-bg);
  color: var(--text);
}

@media (max-width: 700px) {
  .pricing-manager-row {
    grid-template-columns: 1fr 1fr;
  }
}

.pricing-manager-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}
EOF
echo "   ✅ Mis à jour : src/styles/premium.css"

# ---------------------------------------------------------------------------
# 12. Intégration : Dashboard.jsx (écran "Tarifs des services")
# ---------------------------------------------------------------------------

if [ -f "src/dashboard/Dashboard.jsx" ] && ! grep -q "PricingManager" "src/dashboard/Dashboard.jsx"; then
  backup "src/dashboard/Dashboard.jsx"
  python3 - <<'PYEOF'
path = "src/dashboard/Dashboard.jsx"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

import_anchor = 'import ServiceRequests from "./ServiceRequests";'
import_new = import_anchor + '\nimport PricingManager from "./PricingManager";'

render_anchor = '''        <ServiceRequests />

        <Messages />'''

render_new = '''        <ServiceRequests />

        <PricingManager />

        <Messages />'''

changed = False

if import_anchor in content:
    content = content.replace(import_anchor, import_new, 1)
    changed = True

if render_anchor in content:
    content = content.replace(render_anchor, render_new, 1)
    changed = True

if changed:
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("   ✅ Dashboard.jsx : écran 'Tarifs des services' ajouté")
else:
    print("   ⚠️  Dashboard.jsx : ancres introuvables, ajoutez <PricingManager /> manuellement")
PYEOF
else
  echo "   ⏭  Dashboard.jsx déjà à jour (ou introuvable)"
fi

# ---------------------------------------------------------------------------
# Fin
# ---------------------------------------------------------------------------

echo ""
echo "✅ Terminé ! Résumé des changements :"
echo "   • /devis-instantane   → pays/ville/devise au choix, partout dans le monde"
echo "   • Dashboard           → nouvel écran 'Tarifs des services' (prix modifiables)"
echo "   • /audit-instantane   → bouton 'Analyser' toujours visible sur mobile"
echo "   • /audit-instantane   → instructions affichées pour obtenir une clé API gratuite"
echo ""
echo "⚠️  Étape obligatoire dans Supabase (une seule fois) :"
echo "   1. Ouvrez votre projet Supabase → SQL Editor → New query"
echo "   2. Collez le contenu de supabase/pricing_settings.sql et exécutez-le"
echo "   3. Sans cette étape, le calculateur et le dashboard fonctionnent quand"
echo "      même (avec les prix par défaut du code), mais vous ne pourrez pas"
echo "      encore enregistrer de nouveaux tarifs depuis le dashboard."
echo ""
echo "Pour la clé API PageSpeed (pour lever la limite 'Trop de demandes') :"
echo "   → Les instructions complètes sont maintenant affichées directement"
echo "     sur la page /audit-instantane, sous le formulaire."
echo ""
echo "Prochaines étapes :"
echo "   npm install && npm run dev"
