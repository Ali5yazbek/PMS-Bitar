<?php
/**
 * NLPEngine — Advanced Multilingual Hybrid Natural Language Understanding Engine
 * Supports English, French, and Arabic (with RTL detection), Entity Caching,
 * Contextual Follow-up Detection, Autonomous Tool Intents, and Prompt-Injection Defense.
 */
class NLPEngine {
    private $db;
    private static $cachedTenants = null;
    private static $cachedBuildings = null;
    private static $cachedApartments = null;

    // Synonym Dictionary mapping variations (EN / FR / AR) to canonical terms
    private $synonyms = [
        'rent'        => ['rent', 'lease', 'payment', 'installment', 'rental', 'monthly', 'loyer', 'paiement', 'ايجار', 'إيجار', 'دفعات'],
        'overdue'     => ['overdue', 'late', 'unpaid', 'owing', 'debt', 'debtor', 'debtors', 'arrears', 'delinquent', 'missing', 'behind', 'impayé', 'retard', 'dette', 'متأخر', 'غير مدفوع', 'ديون', 'متأخرات'],
        'expiring'    => ['expiring', 'expire', 'expires', 'ending', 'end', 'renewal', 'renew', 'soon', 'upcoming', 'finish', 'expiration', 'renouvellement', 'ينتهي', 'انتهاء', 'تجديد'],
        'tenant'      => ['tenant', 'tenants', 'renter', 'renters', 'occupant', 'resident', 'client', 'lessee', 'locataire', 'locataires', 'مستأجر', 'مستأجرين', 'ساكن'],
        'building'    => ['building', 'buildings', 'property', 'properties', 'tower', 'complex', 'block', 'estate', 'immeuble', 'bâtiment', 'مبنى', 'مباني', 'عقار', 'بناية'],
        'apartment'   => ['apartment', 'apartments', 'unit', 'units', 'flat', 'flats', 'room', 'suite', 'apt', 'appartement', 'شقة', 'شقق', 'وحدة'],
        'vacant'      => ['vacant', 'empty', 'available', 'free', 'unoccupied', 'open', 'disponible', 'vide', 'شاغر', 'شاغرة', 'فارغة', 'متاح'],
        'maintenance' => ['maintenance', 'repair', 'repairs', 'fix', 'fixing', 'ac', 'aircon', 'broken', 'issue', 'problem', 'task', 'tasks', 'service', 'ticket', 'tickets', 'panne', 'réparation', 'صيانة', 'تصليح', 'عطل', 'مكيف'],
        'fuel'        => ['fuel', 'diesel', 'gas', 'petrol', 'tank', 'reserve', 'level', 'liters', 'refill', 'carburant', 'mazout', 'وقود', 'مازوت', 'ديزل', 'خزان'],
        'energy'      => ['energy', 'electricity', 'power', 'generator', 'generators', 'kwh', 'meter', 'consumption', 'grid', 'subscription', 'électricité', 'générateur', 'كهرباء', 'مولد', 'مولدات', 'طاقة', 'عداد'],
        'expense'     => ['expense', 'expenses', 'cost', 'costs', 'spending', 'spent', 'outflow', 'bill', 'bills', 'dépense', 'coût', 'مصاريف', 'تكاليف', 'نفقات'],
        'purchase'    => ['purchase', 'purchases', 'bought', 'receipt', 'agent purchase', 'apartment cost', 'achat', 'achats', 'مشتريات', 'فواتير شراء'],
        'financial'   => ['financial', 'finance', 'money', 'revenue', 'income', 'profit', 'loss', 'summary', 'overview', 'balance', 'cash', 'cfa', 'financier', 'revenu', 'bénéfice', 'مالي', 'مالية', 'ارباح', 'أرباح', 'دخل', 'ملخص'],
        'supplier'    => ['supplier', 'suppliers', 'vendor', 'vendors', 'contractor', 'purchase order', 'po', 'fournisseur', 'مورد', 'موردين'],
        'insurance'   => ['insurance', 'deposit', 'security', 'caution', 'coverage', 'guarantee', 'assurance', 'تأمين', 'ضمان'],
        'construction'=> ['construction', 'project', 'projects', 'build', 'building work', 'renovation', 'contractor', 'chantier', 'بناء', 'انشاء', 'إنشاءات', 'ورشة'],
        'pos'         => ['pos', 'sale', 'sales', 'shop', 'store', 'cashier', 'warehouse', 'inventory', 'stock', 'vente', 'caisse', 'مبيعات', 'مخزن', 'مستودع', 'كاشير'],
        'user'        => ['user', 'users', 'staff', 'employee', 'employees', 'agent', 'agents', 'manager', 'admin', 'role', 'worker', 'technician', 'utilisateur', 'employé', 'موظف', 'موظفين', 'عمال', 'وكيل'],
        'report'      => ['report', 'reports', 'daily', 'log', 'logs', 'activity', 'history', 'audit', 'rapport', 'journal', 'تقرير', 'تقارير', 'سجل'],
        'approve'     => ['approve', 'accept', 'confirm', 'validate', 'authorize', 'approuver', 'valider', 'موافقة', 'اعتماد', 'اقبل', 'وافق'],
        'reject'      => ['reject', 'decline', 'deny', 'refuse', 'rejeter', 'refuser', 'رفض', 'ارفض'],
        'diagnostic'  => ['diagnostic', 'diagnostics', 'health', 'checkup', 'status check', 'bug', 'slow', 'error', 'errors', 'audit system', 'self check', 'فحص النظام', 'حالة النظام', 'أخطاء'],
        'insight'     => ['recommend', 'recommendation', 'recommendations', 'suggest', 'advice', 'tips', 'optimize', 'improve', 'insight', 'insights', 'anomaly', 'anomalies', 'risk', 'attention', 'priority', 'conseil', 'توصيات', 'نصائح', 'تنبيهات', 'مخاطر'],
        'navigate'    => ['navigate', 'go to', 'open page', 'take me to', 'switch to', 'aller à', 'ouvrir', 'افتح صفحة', 'انتقل الى'],
    ];

    // Intent Definitions with weights
    private $intents = [
        'approve_purchase' => [
            'required' => ['approve'],
            'boost'    => ['purchase', 'expense', 'cost', 'receipt', 'achat', 'مشتريات'],
            'keywords' => ['approve purchase', 'approve cost', 'approve receipt', 'accept purchase', 'approuver achat', 'موافقة على الشراء']
        ],
        'reject_purchase' => [
            'required' => ['reject'],
            'boost'    => ['purchase', 'expense', 'cost', 'receipt'],
            'keywords' => ['reject purchase', 'decline purchase', 'reject cost', 'رفض الشراء']
        ],
        'approve_maintenance' => [
            'required' => ['approve'],
            'boost'    => ['maintenance', 'task', 'ac'],
            'keywords' => ['approve maintenance', 'approve task', 'approve ac', 'موافقة على الصيانة']
        ],
        'pending_purchases' => [
            'required' => ['purchase'],
            'boost'    => ['pending', 'review', 'agent', 'apartment', 'expense'],
            'keywords' => ['pending purchases', 'agent purchases', 'apartment costs', 'purchase review', 'unapproved purchases', 'مشتريات معلقة', 'تكاليف الشقق']
        ],
        'system_diagnostics' => [
            'required' => ['diagnostic'],
            'boost'    => ['report', 'financial', 'maintenance'],
            'keywords' => ['system diagnostics', 'run diagnostics', 'system health', 'health check', 'check errors', 'system status', 'database health', 'فحص النظام', 'حالة النظام']
        ],
        'proactive_insights' => [
            'required' => ['insight'],
            'boost'    => ['financial', 'overdue', 'maintenance', 'fuel'],
            'keywords' => ['recommendations', 'proactive insights', 'what should i do', 'what needs attention', 'anomalies', 'risk analysis', 'action items', 'توصيات', 'ما الذي يحتاج انتباهي']
        ],
        'worker_reports' => [
            'required' => ['user', 'maintenance'],
            'boost'    => ['report'],
            'keywords' => ['worker report', 'worker reports', 'technician report', 'maintenance workers', 'field workers', 'تقرير العمال', 'تقارير الفنيين']
        ],
        'navigate_to' => [
            'required' => ['navigate'],
            'boost'    => [],
            'keywords' => ['go to', 'open page', 'take me to', 'navigate to', 'افتح صفحة', 'انتقل إلى']
        ],
        'overdue_rent' => [
            'required' => ['overdue'],
            'boost'    => ['rent', 'tenant'],
            'keywords' => ['who owes', 'haven\'t paid', 'not paid', 'unpaid rent', 'late payment', 'overdue invoices', 'الإيجارات المتأخرة', 'من لم يدفع', 'loyers impayés']
        ],
        'top_debtors' => [
            'required' => ['overdue'],
            'boost'    => ['tenant'],
            'keywords' => ['top debtors', 'biggest debtors', 'most debt', 'highest debt', 'owe the most', 'worst payers', 'أكبر المدينين']
        ],
        'expiring_contracts' => [
            'required' => ['expiring'],
            'boost'    => ['rent', 'tenant', 'apartment'],
            'keywords' => ['contracts expiring', 'leases ending', 'upcoming renewals', 'about to expire', 'contract end', 'العقود المنتهية', 'عقود تنتهي قريبا', 'contrats expirants']
        ],
        'pending_contracts' => [
            'required' => [],
            'boost'    => ['tenant', 'rent'],
            'keywords' => ['pending contract', 'pending contracts', 'unsigned', 'awaiting signature', 'draft contract', 'unapproved contract', 'عقود معلقة']
        ],
        'financial_summary' => [
            'required' => ['financial'],
            'boost'    => ['rent', 'expense', 'building'],
            'keywords' => ['financial summary', 'how much money', 'total revenue', 'net profit', 'cash flow', 'financial overview', 'how are we doing', 'executive summary', 'الملخص المالي', 'الأرباح والإيرادات', 'bilan financier']
        ],
        'building_profit_loss' => [
            'required' => ['building', 'financial'],
            'boost'    => ['expense', 'rent'],
            'keywords' => ['building profit', 'profit and loss', 'p&l', 'net income per building', 'most profitable building', 'losing money', 'أرباح المباني']
        ],
        'building_expenses' => [
            'required' => ['building', 'expense'],
            'boost'    => [],
            'keywords' => ['building expenses', 'cost of building', 'spent on building', 'building costs', 'مصاريف المبنى']
        ],
        'building_summary' => [
            'required' => ['building'],
            'boost'    => ['apartment'],
            'keywords' => ['list buildings', 'all buildings', 'our properties', 'how many buildings', 'building overview', 'tell me about building', 'جميع المباني', 'قائمة المباني']
        ],
        'vacant_apartments' => [
            'required' => ['vacant'],
            'boost'    => ['apartment', 'building'],
            'keywords' => ['vacant apartments', 'empty units', 'available flats', 'free apartments', 'what is available', 'الشقق الشاغرة', 'شقق متاحة', 'appartements vacants']
        ],
        'apartment_info' => [
            'required' => ['apartment'],
            'boost'    => ['tenant', 'rent'],
            'keywords' => ['apartment info', 'unit details', 'who lives in', 'status of apartment', 'معلومات الشقة']
        ],
        'tenant_info' => [
            'required' => ['tenant'],
            'boost'    => ['rent', 'apartment'],
            'keywords' => ['tenant info', 'find tenant', 'search tenant', 'who is', 'tell me about', 'everything about', 'details for', 'معلومات المستأجر', 'كل شيء عن']
        ],
        'rent_dashboard' => [
            'required' => ['rent'],
            'boost'    => ['financial'],
            'keywords' => ['rent dashboard', 'rent collection', 'collection rate', 'total rent', 'rent statistics', 'rent status', 'تحصيل الإيجارات']
        ],
        'maintenance_tasks' => [
            'required' => ['maintenance'],
            'boost'    => ['apartment', 'building'],
            'keywords' => ['maintenance tasks', 'ac maintenance', 'pending repairs', 'broken ac', 'open tickets', 'scheduled maintenance', 'مهام الصيانة', 'طلبات الصيانة']
        ],
        'fuel_status' => [
            'required' => ['fuel'],
            'boost'    => ['energy'],
            'keywords' => ['fuel status', 'diesel level', 'fuel reserve', 'how much fuel', 'tank level', 'fuel stock', 'مستوى الوقود', 'احتياطي المازوت']
        ],
        'energy_overview' => [
            'required' => ['energy'],
            'boost'    => ['building', 'apartment'],
            'keywords' => ['energy overview', 'electricity', 'generator status', 'power consumption', 'meter readings', 'unpaid electricity', 'حالة المولدات', 'الكهرباء والمولدات']
        ],
        'suppliers_summary' => [
            'required' => ['supplier'],
            'boost'    => ['expense'],
            'keywords' => ['suppliers', 'vendors', 'purchase orders', 'who do we buy from', 'top suppliers', 'الموردين']
        ],
        'expenses_summary' => [
            'required' => ['expense'],
            'boost'    => ['financial'],
            'keywords' => ['all expenses', 'total expenses', 'where is money going', 'spending breakdown', 'expense categories', 'إجمالي المصاريف']
        ],
        'insurance_summary' => [
            'required' => ['insurance'],
            'boost'    => ['tenant', 'financial'],
            'keywords' => ['insurance', 'security deposits', 'total saved', 'insurance accounts', 'caution money', 'التأمينات']
        ],
        'daily_reports' => [
            'required' => ['report'],
            'boost'    => ['energy', 'fuel'],
            'keywords' => ['daily reports', 'agent reports', 'field logs', 'recent logs', 'generator logs', 'التقارير اليومية']
        ],
        'construction_status' => [
            'required' => ['construction'],
            'boost'    => ['building', 'expense'],
            'keywords' => ['construction projects', 'ongoing construction', 'renovations', 'project budget', 'مشاريع البناء']
        ],
        'pos_sales' => [
            'required' => ['pos'],
            'boost'    => ['financial'],
            'keywords' => ['pos sales', 'store sales', 'warehouse', 'inventory', 'shop revenue', 'المبيعات والمستودع']
        ],
        'users_overview' => [
            'required' => ['user'],
            'boost'    => [],
            'keywords' => ['all users', 'staff list', 'employees', 'who works here', 'agents', 'managers', 'الموظفين', 'المستخدمين']
        ],
        'greeting' => [
            'required' => [],
            'boost'    => [],
            'keywords' => ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening', 'greetings', 'bonjour', 'salut', 'مرحبا', 'السلام عليكم', 'اهلا']
        ],
        'help' => [
            'required' => [],
            'boost'    => [],
            'keywords' => ['help', 'what can you do', 'commands', 'how to use', 'capabilities', 'features', 'aide', 'مساعدة', 'ماذا يمكنك ان تفعل']
        ],
        'recommendations' => [
            'required' => ['insight'],
            'boost'    => [],
            'keywords' => ['recommend', 'recommendations', 'suggest', 'suggestions', 'advice', 'tips', 'what should i do', 'optimize', 'improve']
        ]
    ];

    public function __construct($db) {
        $this->db = $db;
    }

    /**
     * Detect user language (en, fr, ar) and RTL orientation
     */
    public function detectLanguage(string $text): array {
        if (preg_match('/[\x{0600}-\x{06FF}]/u', $text)) {
            return ['lang' => 'ar', 'is_rtl' => true];
        }
        $lower = mb_strtolower($text, 'UTF-8');
        $frMarkers = ['bonjour', 'salut', 'loyer', 'immeuble', 'locataire', 'combien', 'quel', 'quels', 'quelles', 'appartement', 'dépense', 'facture', 'carburant', 'maintenant'];
        foreach ($frMarkers as $m) {
            if (preg_match('/\b' . preg_quote($m, '/') . '\b/u', $lower)) {
                return ['lang' => 'fr', 'is_rtl' => false];
            }
        }
        return ['lang' => 'en', 'is_rtl' => false];
    }

    /**
     * Sanitize user message and detect prompt-injection or SQL/system manipulation attempts
     */
    public function inspectSecurity(string $text): array {
        $lower = strtolower($text);
        $patterns = [
            '/ignore\s+(all\s+)?(previous|prior|system)\s+instructions/i',
            '/reveal\s+(your\s+)?(system\s+prompt|api\s+key|secret|password|jwt)/i',
            '/bypass\s+(security|permission|role|auth)/i',
            '/;\s*(drop|truncate|delete\s+from|alter\s+table|update\s+users\s+set\s+role)/i',
        ];
        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $lower)) {
                return [
                    'safe' => false,
                    'reason' => 'Prompt injection or unauthorized privilege escalation pattern detected.'
                ];
            }
        }
        return ['safe' => true, 'reason' => null];
    }

    /**
     * Main entry point to analyze a user's message
     */
    public function analyze($message, array $conversationContext = []) {
        $langInfo = $this->detectLanguage($message);
        $security = $this->inspectSecurity($message);

        $cleanMsg = $this->normalize($message);
        $tokens = explode(' ', $cleanMsg);
        $canonicalTokens = $this->mapSynonyms($tokens);

        // 1. Extract Entities from message (cached per request)
        $entities = $this->extractEntities($message);

        // 2. Detect if this is a contextual follow-up ("what about its expenses?", "and who lives there?", "approve it")
        $isFollowUp = $this->isFollowUpQuery($message, $entities);
        if ($isFollowUp && !empty($conversationContext)) {
            if (empty($entities['building']) && !empty($conversationContext['last_building'])) {
                $entities['building'] = $conversationContext['last_building'];
                $entities['inherited_from_context'] = true;
            }
            if (empty($entities['tenant']) && !empty($conversationContext['last_tenant'])) {
                $entities['tenant'] = $conversationContext['last_tenant'];
                $entities['inherited_from_context'] = true;
            }
            if (empty($entities['apartment_code']) && !empty($conversationContext['last_apartment'])) {
                $entities['apartment_code'] = $conversationContext['last_apartment'];
                $entities['inherited_from_context'] = true;
            }
            if (empty($entities['record_id']) && !empty($conversationContext['last_record_id'])) {
                $entities['record_id'] = $conversationContext['last_record_id'];
            }
        }

        // 3. Score Intents
        $scores = [];
        foreach ($this->intents as $intentName => $rules) {
            $score = 0;

            foreach ($rules['keywords'] as $phrase) {
                if (mb_stripos($message, $phrase, 0, 'UTF-8') !== false || strpos($cleanMsg, $phrase) !== false) {
                    $score += 50;
                }
            }

            if (!empty($rules['required'])) {
                $hasAllRequired = true;
                foreach ($rules['required'] as $req) {
                    if (!in_array($req, $canonicalTokens)) {
                        $hasAllRequired = false;
                        break;
                    }
                }
                if ($hasAllRequired) {
                    $score += 30 * count($rules['required']);
                }
            }

            foreach ($rules['boost'] as $boost) {
                if (in_array($boost, $canonicalTokens)) {
                    $score += 10;
                }
            }

            if ($score > 0) {
                $scores[$intentName] = $score;
            }
        }

        // 4. Entity-Driven Fallbacks
        if (empty($scores)) {
            if (!empty($entities['tenant'])) {
                $scores['tenant_info'] = 45;
            } elseif (!empty($entities['apartment_code'])) {
                $scores['apartment_info'] = 45;
            } elseif (!empty($entities['building'])) {
                if (in_array('expense', $canonicalTokens)) {
                    $scores['building_expenses'] = 45;
                } elseif (in_array('vacant', $canonicalTokens)) {
                    $scores['vacant_apartments'] = 45;
                } else {
                    $scores['building_summary'] = 40;
                }
            }
        }

        // Boost specific entity dossier if user asks "everything about X" or mentions a specific tenant/apartment
        if (!empty($entities['tenant']) && ($scores['tenant_info'] ?? 0) < 60 && !in_array('overdue', $canonicalTokens)) {
            $scores['tenant_info'] = max($scores['tenant_info'] ?? 0, 65);
        }
        if (!empty($entities['apartment_code']) && empty($entities['tenant']) && ($scores['apartment_info'] ?? 0) < 60) {
            $scores['apartment_info'] = max($scores['apartment_info'] ?? 0, 62);
        }

        arsort($scores);
        $topIntent = !empty($scores) ? array_key_first($scores) : 'universal_search';
        $confidence = !empty($scores) ? reset($scores) : 0;

        if ($confidence < 20 && $topIntent !== 'greeting' && $topIntent !== 'help') {
            $topIntent = 'universal_search';
        }

        return [
            'intent'           => $topIntent,
            'confidence'       => $confidence,
            'entities'         => $entities,
            'canonical_tokens' => $canonicalTokens,
            'language'         => $langInfo['lang'],
            'is_rtl'           => $langInfo['is_rtl'],
            'security'         => $security,
            'is_follow_up'     => $isFollowUp,
            'all_scores'       => $scores
        ];
    }

    private function isFollowUpQuery(string $message, array $entities): bool {
        $lower = mb_strtolower(trim($message), 'UTF-8');
        $pronouns = [
            '/\b(its|his|her|their|that building|this building|that tenant|this tenant|that apartment|this apartment|there|him|it)\b/i',
            '/\b(what about|how about|and the|also show|approve it|reject it)\b/i',
            '/(وماذا عن|عنه|عنها|له|لها|هذا المبنى|هذه الشقة|الموافقة عليه)/u'
        ];
        foreach ($pronouns as $p) {
            if (preg_match($p, $lower)) {
                return true;
            }
        }
        return false;
    }

    private function normalize($text) {
        $text = mb_strtolower(trim($text), 'UTF-8');
        $text = preg_replace('/[^\p{L}\p{N}\s\-]/u', ' ', $text);
        $text = preg_replace('/\s+/', ' ', $text);
        return trim($text);
    }

    private function mapSynonyms($tokens) {
        $canonical = [];
        foreach ($tokens as $token) {
            foreach ($this->synonyms as $canon => $synList) {
                if (in_array($token, $synList, true)) {
                    $canonical[] = $canon;
                }
            }
        }
        return array_unique($canonical);
    }

    private function loadCachedCatalog(): void {
        if (self::$cachedTenants === null) {
            try {
                self::$cachedTenants = $this->db->query("SELECT id, full_name FROM tenants")->fetchAll(PDO::FETCH_ASSOC) ?: [];
            } catch (\Throwable $e) {
                self::$cachedTenants = [];
            }
        }
        if (self::$cachedBuildings === null) {
            try {
                self::$cachedBuildings = $this->db->query("SELECT id, name FROM buildings")->fetchAll(PDO::FETCH_ASSOC) ?: [];
            } catch (\Throwable $e) {
                self::$cachedBuildings = [];
            }
        }
        if (self::$cachedApartments === null) {
            try {
                self::$cachedApartments = $this->db->query("SELECT id, code, building_id FROM apartments")->fetchAll(PDO::FETCH_ASSOC) ?: [];
            } catch (\Throwable $e) {
                self::$cachedApartments = [];
            }
        }
    }

    private function extractEntities($rawText) {
        $this->loadCachedCatalog();

        $entities = [
            'tenant'            => null,
            'tenant_id'         => null,
            'building'          => null,
            'building_id'       => null,
            'apartment_code'    => null,
            'apartment_id'      => null,
            'record_id'         => null,
            'timeframe'         => null,
            'numbers'           => [],
            'navigation_target' => null,
        ];

        $lowerText = mb_strtolower($rawText, 'UTF-8');

        // 1. Extract explicit ID (#12 or id 12)
        if (preg_match('/(?:#|id\s*|number\s*|رقم\s*)(\d{1,8})\b/iu', $rawText, $idMatch)) {
            $entities['record_id'] = (int)$idMatch[1];
        }

        // 2. Extract numbers
        if (preg_match_all('/\b\d+\b/', $rawText, $matches)) {
            $entities['numbers'] = array_map('intval', $matches[0]);
        }

        // 3. Extract Timeframe
        if (preg_match('/(\d+)\s*(day|days|week|weeks|month|months|year|years|يوم|أيام|شهر|أشهر)/iu', $lowerText, $m)) {
            $val = (int)$m[1];
            $unit = $m[2];
            if (strpos($unit, 'week') === 0) $val *= 7;
            if (strpos($unit, 'month') === 0 || strpos($unit, 'شهر') !== false || strpos($unit, 'أشهر') !== false) $val *= 30;
            if (strpos($unit, 'year') === 0) $val *= 365;
            $entities['timeframe'] = $val;
        } elseif (strpos($lowerText, 'this month') !== false || strpos($lowerText, 'هذا الشهر') !== false) {
            $entities['timeframe'] = 30;
        } elseif (strpos($lowerText, 'this week') !== false || strpos($lowerText, 'هذا الأسبوع') !== false) {
            $entities['timeframe'] = 7;
        }

        // 4. Match Building Name
        foreach (self::$cachedBuildings as $b) {
            $bName = mb_strtolower(trim($b['name'] ?? ''), 'UTF-8');
            if ($bName !== '' && mb_strpos($lowerText, $bName, 0, 'UTF-8') !== false) {
                $entities['building'] = $b['name'];
                $entities['building_id'] = (int)$b['id'];
                break;
            }
        }

        // 5. Match Apartment Code (e.g., "Apt A1", "apartment B2", "شقة A1", or standalone code in catalog)
        if (preg_match('/\b(?:apt|apartment|unit|flat|appartement|شقة)\s*([a-z0-9\-]{1,8})\b/iu', $rawText, $aptMatch)) {
            $entities['apartment_code'] = strtoupper($aptMatch[1]);
        } else {
            foreach (self::$cachedApartments as $a) {
                $code = strtolower(trim($a['code'] ?? ''));
                if ($code !== '' && strlen($code) >= 2 && preg_match('/\b' . preg_quote($code, '/') . '\b/i', $lowerText)) {
                    $entities['apartment_code'] = $a['code'];
                    $entities['apartment_id'] = (int)$a['id'];
                    break;
                }
            }
        }

        // 6. Match Tenant Name (Full or Partial >= 3 chars)
        $bestMatch = null;
        $highestScore = 0;
        $stopWords = ['the', 'and', 'for', 'who', 'what', 'how', 'are', 'all', 'rent', 'info', 'about', 'show', 'list', 'tell', 'everything', 'tenant', 'building', 'apartment', 'from', 'with'];

        foreach (self::$cachedTenants as $t) {
            $tName = mb_strtolower(trim($t['full_name'] ?? ''), 'UTF-8');
            if ($tName === '') continue;

            if (mb_strpos($lowerText, $tName, 0, 'UTF-8') !== false) {
                $entities['tenant'] = $t['full_name'];
                $entities['tenant_id'] = (int)$t['id'];
                break;
            }

            $parts = preg_split('/\s+/u', $tName);
            $matchCount = 0;
            foreach ($parts as $part) {
                if (mb_strlen($part, 'UTF-8') >= 3 && !in_array($part, $stopWords, true)) {
                    if (preg_match('/\b' . preg_quote($part, '/') . '\b/iu', $lowerText)) {
                        $matchCount++;
                    }
                }
            }

            if ($matchCount > $highestScore) {
                $highestScore = $matchCount;
                $bestMatch = $t;
            }
        }

        if (!$entities['tenant'] && $bestMatch && $highestScore > 0) {
            $entities['tenant'] = $bestMatch['full_name'];
            $entities['tenant_id'] = (int)$bestMatch['id'];
        }

        // 7. Extract Navigation Target if present
        $navMap = [
            '/fuel-reserve'          => ['fuel reserve', 'diesel reserve', 'fuel tank', 'احتياطي الوقود'],
            '/maintenance-admin'     => ['maintenance oversight', 'ac maintenance', 'maintenance admin', 'إدارة الصيانة'],
            '/agent-purchase-review' => ['purchase review', 'agent purchases', 'review purchases', 'مراجعة المشتريات'],
            '/apartment-costs'       => ['apartment costs', 'cost report', 'تكاليف الشقق'],
            '/rent-management'       => ['rent management', 'rent invoices', 'إدارة الإيجارات'],
            '/contracts'             => ['contracts', 'leases', 'العقود'],
            '/buildings'             => ['buildings page', 'all buildings', 'صفحة المباني'],
            '/tenants'               => ['tenants page', 'tenant directory', 'صفحة المستأجرين'],
            '/energy'                => ['energy management', 'generators page', 'إدارة الطاقة'],
            '/financial-reports'     => ['financial reports', 'finance page', 'التقارير المالية'],
        ];
        foreach ($navMap as $route => $triggers) {
            foreach ($triggers as $t) {
                if (mb_strpos($lowerText, $t, 0, 'UTF-8') !== false) {
                    $entities['navigation_target'] = $route;
                    break 2;
                }
            }
        }

        return $entities;
    }
}
