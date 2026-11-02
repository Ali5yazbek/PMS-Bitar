<?php
/**
 * ═══════════════════════════════════════════════════════════════════
 *  Custom NLP Engine – Bitar PMS
 *  Provides fuzzy matching, multi-lingual synonym detection, and
 *  entity extraction without relying on external LLM APIs.
 * ═══════════════════════════════════════════════════════════════════
 */

class NLPEngine {
    private $db;

    public function __construct($db = null) {
        $this->db = $db;
    }

    
    // Stop words to remove from queries to increase accuracy
    private $stopWords = [
        // English
        'is', 'the', 'a', 'an', 'and', 'or', 'but', 'can', 'you', 'show', 'me', 'what', 'are', 'please', 'tell', 'about', 'of', 'in', 'on', 'at', 'to', 'for', 'give', 'list', 'i', 'want', 'need', 'know',
        // Arabic
        'هل', 'يمكنك', 'ان', 'تخبرني', 'عن', 'ما', 'هي', 'ال', 'في', 'على', 'من', 'الى', 'اريد', 'معرفة', 'قائمة', 'ب', 'لي', 'الرجاء', 'اعطني',
        // French
        'est', 'le', 'la', 'les', 'un', 'une', 'et', 'ou', 'mais', 'peux', 'tu', 'me', 'montrer', 'quoi', 'sont', 'svp', 'dire', 'sur', 'de', 'dans', 'pour', 'donner', 'liste', 'je', 'veux', 'savoir'
    ];

    // Intent dictionary mapping to English, Arabic, and French synonyms
    private $intentMap = [
        'agent_purchases'     => ['purchase', 'purchases', 'purchased', 'bought', 'supplier cost', 'material cost', 'apartment cost', 'cost report', 'مشتريات', 'شراء', 'تكاليف الشقق', 'achat', 'achats'],
        'ac_maintenance'      => ['ac maintenance', 'ac cleaning', 'ac repair', 'air condition', 'pending maintenance', 'صيانة المكيفات', 'تنظيف المكيفات', 'مكيف', 'climatiseur', 'climatisation'],
        'audit_activities'    => ['audit', 'audit logs', 'activity logs', 'recent activities', 'who did what', 'سجل النشاطات', 'انشطة اليوم', 'audit log'],
        'expiring_contracts'  => ['expiring', 'expire', 'ended', 'renew', 'انتهاء', 'عقود', 'تجديد', 'تنتهي', 'expirant', 'contrat', 'renouveler'],
        'overdue_rent'        => ['overdue', 'late', 'unpaid', 'delinquent', 'arrears', 'متأخر', 'غير مدفوع', 'متأخرات', 'retard', 'impayé', 'arriérés'],
        'building_income'     => ['income', 'revenue', 'collected', 'earnings', 'دخل', 'ايرادات', 'ارباح', 'revenu', 'recettes', 'gains'],
        'building_expenses'   => ['expense', 'cost', 'spending', 'expenditure', 'مصروفات', 'تكاليف', 'نفقات', 'dépense', 'coût', 'dépenses'],
        'building_summary'    => ['building summary', 'overview', 'building report', 'ملخص', 'تقرير', 'نظرة عامة', 'résumé', 'rapport', 'aperçu'],
        'tenant_info'         => ['tenant', 'resident', 'occupant', 'renter', 'lives', 'مستأجر', 'ساكن', 'مقيم', 'locataire', 'résident', 'habitant'],
        'vacant_apartments'   => ['vacant', 'empty', 'available', 'unoccupied', 'فارغ', 'متاح', 'شاغر', 'vacant', 'vide', 'disponible'],
        'apartment_info'      => ['apartment', 'unit', 'flat', 'شقة', 'وحدة', 'appartement', 'unité'],
        'rent_dashboard'      => ['dashboard', 'rent overview', 'total rent', 'لوحة التحكم', 'ملخص الايجار', 'tableau de bord', 'loyer total'],
        'maintenance_tasks'   => ['maintenance', 'repair', 'fix', 'workshop', 'صيانة', 'تصليح', 'اصلاح', 'ورشة', 'entretien', 'réparation', 'réparer'],
        'fuel_status'         => ['fuel', 'diesel', 'mazout', 'reserve', 'وقود', 'ديزل', 'مازوت', 'carburant', 'diesel', 'réserve'],
        'energy_overview'     => ['energy overview', 'energy', 'electricity', 'generator', 'power', 'kwh', 'كهرباء', 'طاقة', 'مولد', 'énergie', 'électricité', 'générateur'],
        'suppliers_summary'   => ['supplier', 'vendor', 'purchase', 'مورد', 'بائع', 'fournisseur', 'vendeur'],
        'expenses_summary'    => ['expenses summary', 'total spent', 'اجمالي المصروفات', 'dépenses totales'],
        'insurance_summary'   => ['insurance', 'coverage', 'تأمين', 'تغطية', 'assurance', 'couverture'],
        'top_debtors'         => ['debtor', 'debt', 'owe', 'balance', 'مدين', 'ديون', 'رصيد', 'débiteur', 'dette', 'doit', 'solde'],
        'unpaid_invoices'     => ['who didn\'t pay', 'not paid', 'unpaid', 'who still', 'لم يدفع', 'non payé', 'qui n\'a pas'],
        'loss_analysis'       => ['losing money', 'loss', 'worst building', 'خسارة', 'perte', 'perd de l\'argent'],
        'recommendations'     => ['what should i do', 'recommend', 'advice', 'ماذا أفعل', 'نصيحة', 'que dois-je faire', 'recommander'],
        'daily_reports'       => ['daily report', 'agent report', 'field report', 'تقرير يومي', 'تقرير المندوب', 'rapport quotidien', 'rapport agent'],
        'pos_summary'         => ['pos', 'sales', 'cashier', 'shop', 'مبيعات', 'صندوق', 'كاشير', 'ventes', 'caisse', 'boutique'],
        'construction_status' => ['construction', 'project', 'site', 'بناء', 'مشروع', 'موقع', 'construction', 'projet', 'chantier'],
        'help'                => ['help', 'commands', 'capabilities', 'مساعدة', 'اوامر', 'aide', 'commandes', 'capacités'],
        'greeting'            => ['hi', 'hello', 'hey', 'مرحبا', 'اهلا', 'السلام عليكم', 'salut', 'bonjour', 'bonsoir'],
    ];

    /**
     * Analyze a raw string and return structured intent and entities
     */
        public function analyze($rawMessage) {
        $message = mb_strtolower(trim($rawMessage), 'UTF-8');
        
        // 1. Extract entities (now with DB fuzzy matching)
        $entities = $this->extractEntities($message);

        // 2. Normalize Text
        $normalized = preg_replace('/[^\p{L}\p{N}\s]/u', '', $message);
        
        // 3. Tokenize and remove stop words
        $tokens = explode(' ', $normalized);
        $cleanTokens = [];
        foreach ($tokens as $token) {
            $t = trim($token);
            if (!empty($t) && !in_array($t, $this->stopWords)) {
                $cleanTokens[] = $t;
            }
        }
        $cleanString = implode(' ', $cleanTokens);

        // 4. Score Intents
        $bestIntent = 'unknown';
        $highestScore = 0;

        foreach ($this->intentMap as $intent => $synonyms) {
            $score = 0;
            foreach ($synonyms as $synonym) {
                // Exact Match using word boundaries
                $paddedClean = ' ' . $cleanString . ' ';
                if (mb_strpos($paddedClean, ' ' . $synonym . ' ') !== false) {
                    $words = count(explode(' ', $synonym));
                    $score += (100 * $words);
                }
                
                // Fuzzy match against individual tokens
                foreach ($cleanTokens as $token) {
                    if (mb_strlen($token) >= 4 && mb_strlen($synonym) >= 4) {
                        $distance = levenshtein($token, $synonym);
                        if ($distance === 1) {
                            $score += 80;
                        } elseif ($distance === 2 && mb_strlen($token) >= 6 && mb_strlen($synonym) >= 6) {
                            $score += 50;
                        }
                    }
                }
            }
            
            if ($score > $highestScore) {
                $highestScore = $score;
                $bestIntent = $intent;
            }
        }

        // 5. Fallbacks and defaults
        if ($highestScore < 50) {
            $bestIntent = 'unknown';
        }

        // 6. Smart Entity-Based Intent Inference
        if ($bestIntent === 'unknown') {
            if (!empty($entities['tenant_name'])) {
                $bestIntent = 'tenant_info';
                $highestScore = 80; // Boost confidence
            } elseif (!empty($entities['building_name'])) {
                $bestIntent = 'building_summary';
                $highestScore = 80;
            }
        }

        return [
            'intent' => $bestIntent,
            'entities' => $entities,
            'confidence' => $highestScore
        ];
    }

    private function extractEntities($message) {
        $entities = [
            'days' => 60,
            'building_name' => null,
            'tenant_name' => null
        ];

        // Basic Regex Days
        if (preg_match('/(\d+)\s*(?:day|days|jour|jours)/i', $message, $m)) {
            $entities['days'] = (int)$m[1];
        } elseif (preg_match('/this\s*month|ce\s*mois/i', $message)) {
            $entities['days'] = 30;
        } elseif (preg_match('/(\d+)\s*(?:month|months|mois)/i', $message, $m)) {
            $entities['days'] = (int)$m[1] * 30;
        }

        $tokens = explode(' ', preg_replace('/[^\p{L}\p{N}\s]/u', '', $message));
        
        // Advanced DB Fuzzy Extraction
        if ($this->db) {
            // Check Tenants
            $stmt = $this->db->query("SELECT full_name FROM tenants");
            $tenants = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            // Generate bi-grams from user message
            $bigrams = [];
            for ($i = 0; $i < count($tokens) - 1; $i++) {
                if (strlen($tokens[$i]) > 2 && strlen($tokens[$i+1]) > 2) {
                    $bigrams[] = $tokens[$i] . ' ' . $tokens[$i+1];
                }
            }
            
            $bestTenant = null;
            $bestTenantScore = 3; // Max levenshtein distance allowed

            foreach ($tenants as $tName) {
                $tLower = mb_strtolower($tName, 'UTF-8');
                
                // Check exact substring first
                if (mb_strpos($message, $tLower) !== false) {
                    $bestTenant = $tName;
                    break;
                }
                
                // Check fuzzy bigrams
                foreach ($bigrams as $bg) {
                    $dist = levenshtein($bg, $tLower);
                    if ($dist < $bestTenantScore) {
                        $bestTenantScore = $dist;
                        $bestTenant = $tName;
                    }
                }
            }
            if ($bestTenant) $entities['tenant_name'] = $bestTenant;

            // Check Buildings
            $stmt = $this->db->query("SELECT name FROM buildings");
            $buildings = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            $bestBuilding = null;
            $bestBuildingScore = 2;
            foreach ($buildings as $bName) {
                $bLower = mb_strtolower($bName, 'UTF-8');
                if (mb_strpos($message, $bLower) !== false) {
                    $bestBuilding = $bName;
                    break;
                }
                foreach ($tokens as $token) {
                    if (strlen($token) > 3) {
                        $dist = levenshtein($token, $bLower);
                        if ($dist < $bestBuildingScore) {
                            $bestBuildingScore = $dist;
                            $bestBuilding = $bName;
                        }
                    }
                }
            }
            if ($bestBuilding) $entities['building_name'] = $bestBuilding;
        }

        // Fallbacks for regex if DB fuzzy failed
        if (!$entities['building_name'] && preg_match('/(?:building|bâtiment)\s+["\']?([\p{L}0-9\s\-]+)["\']?/iu', $message, $m)) {
            $entities['building_name'] = trim($m[1]);
        }
        if (!$entities['tenant_name'] && preg_match('/(?:tenant|resident|locataire)\s+["\']?([\p{L}\s]+)["\']?/iu', $message, $m)) {
            $entities['tenant_name'] = trim($m[1]);
        }

        return $entities;
    }
}