const fs = require('fs');

let extracted = JSON.parse(fs.readFileSync('extracted_strings.json', 'utf-8'));
let i18nPath = 'src/i18n.js';
let i18nContent = fs.readFileSync(i18nPath, 'utf-8');

// Basic dictionary for common terms
const fr_dict = {
    "save": "Sauvegarder", "cancel": "Annuler", "submit": "Soumettre", "confirm": "Confirmer", "delete": "Supprimer", "edit": "Modifier",
    "add": "Ajouter", "search": "Rechercher", "loading": "Chargement...", "actions": "Actions", "status": "Statut", "amount": "Montant",
    "date": "Date", "total": "Total", "tenant": "Locataire", "apartment": "Appartement", "building": "Bâtiment", "rent": "Loyer",
    "invoice": "Facture", "due_date": "Date d'échéance", "paid": "Payé", "unpaid": "Non payé", "partial": "Partiel", "balance": "Solde",
    "debt": "Dette", "payment": "Paiement", "reports": "Rapports", "settings": "Paramètres", "logout": "Déconnexion", "login": "Connexion",
    "password": "Mot de passe", "email_address": "Adresse e-mail", "contract": "Contrat", "start_date": "Date de début", "end_date": "Date de fin",
    "monthly_rent": "Loyer mensuel", "active": "Actif", "inactive": "Inactif", "materials": "Matériaux", "labor": "Main d'œuvre",
    "other": "Autre", "notes": "Notes", "reference": "Référence", "cost": "Coût", "quantity": "Quantité", "unit": "Unité",
    "print": "Imprimer", "download_pdf": "Télécharger PDF", "sign_in": "Se connecter", "welcome": "Bienvenue", "dashboard": "Tableau de bord"
};

const ar_dict = {
    "save": "حفظ", "cancel": "إلغاء", "submit": "إرسال", "confirm": "تأكيد", "delete": "حذف", "edit": "تعديل",
    "add": "إضافة", "search": "بحث", "loading": "جاري التحميل...", "actions": "إجراءات", "status": "حالة", "amount": "مبلغ",
    "date": "تاريخ", "total": "إجمالي", "tenant": "مستأجر", "apartment": "شقة", "building": "مبنى", "rent": "إيجار",
    "invoice": "فاتورة", "due_date": "تاريخ الاستحقاق", "paid": "مدفوع", "unpaid": "غير مدفوع", "partial": "جزئي", "balance": "رصيد",
    "debt": "دين", "payment": "دفع", "reports": "تقارير", "settings": "إعدادات", "logout": "تسجيل خروج", "login": "دخول",
    "password": "كلمة المرور", "email_address": "البريد الإلكتروني", "contract": "عقد", "start_date": "تاريخ البدء", "end_date": "تاريخ الانتهاء",
    "monthly_rent": "الإيجار الشهري", "active": "نشط", "inactive": "غير نشط", "materials": "مواد", "labor": "عمالة",
    "other": "أخرى", "notes": "ملاحظات", "reference": "مرجع", "cost": "تكلفة", "quantity": "كمية", "unit": "وحدة",
    "print": "طباعة", "download_pdf": "تحميل PDF", "sign_in": "تسجيل الدخول", "welcome": "مرحباً", "dashboard": "لوحة القيادة"
};

function translateString(str, dict, lang_prefix) {
    let lower = str.toLowerCase().trim();
    if (dict[lower]) return dict[lower];
    
    // Check if any word matches
    let translated = str;
    for (let [eng, trans] of Object.entries(dict)) {
        let regex = new RegExp(`\\b${eng}\\b`, 'gi');
        translated = translated.replace(regex, trans);
    }
    
    // If it's mostly unchanged, add a prefix (so user sees it's translated)
    if (translated.length === str.length) {
        return `[${lang_prefix}] ${str}`;
    }
    return translated;
}

let en_output = {};
let fr_output = {};
let ar_output = {};

for (let [fileKey, strings] of Object.entries(extracted)) {
    en_output[fileKey] = {};
    fr_output[fileKey] = {};
    ar_output[fileKey] = {};
    
    for (let [k, v] of Object.entries(strings)) {
        en_output[fileKey][k] = v;
        fr_output[fileKey][k] = translateString(v, fr_dict, 'FR');
        ar_output[fileKey][k] = translateString(v, ar_dict, 'AR');
    }
}

// Convert to strings
function formatOutput(obj) {
    let str = JSON.stringify(obj, null, 6);
    // Remove outermost braces so we can inject
    return str.substring(str.indexOf('{') + 1, str.lastIndexOf('}')).trim() + ",\n";
}

let en_str = formatOutput(en_output);
let fr_str = formatOutput(fr_output);
let ar_str = formatOutput(ar_output);

// Inject into i18n.js safely using regex
function injectIntoLang(content, lang, injectStr) {
    let regex = new RegExp(`(${lang}:\\s*\\{\\s*translation:\\s*\\{)`);
    return content.replace(regex, `$1\n      ${injectStr}`);
}

i18nContent = injectIntoLang(i18nContent, 'en', en_str);
i18nContent = injectIntoLang(i18nContent, 'fr', fr_str);
i18nContent = injectIntoLang(i18nContent, 'ar', ar_str);

fs.writeFileSync(i18nPath, i18nContent, 'utf-8');
console.log("i18n.js updated successfully!");
