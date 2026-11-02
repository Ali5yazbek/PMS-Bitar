<?php
/**
 * diagnose_rent.php
 * Run: http://localhost/Bitar/backend/diagnose_rent.php
 * Optional: ?tenant_id=XX  or  ?contract_id=XX
 */
require_once __DIR__ . "/config.php";
require_once __DIR__ . "/core/Database.php";

$db    = Database::getInstance()->getConnection();
$today = date("Y-m-d");
$tenantId   = isset($_GET["tenant_id"])   ? (int)$_GET["tenant_id"]   : null;
$contractId = isset($_GET["contract_id"]) ? (int)$_GET["contract_id"] : null;

function badge(string $type, string $text): string {
    $map = ["ok"=>"#2ecc71","warn"=>"#f39c12","fail"=>"#e74c3c","info"=>"#3498db"];
    $c = $map[$type] ?? "#888";
    return "<span style=\"background:$c;color:#fff;padding:2px 8px;border-radius:4px;font-size:12px;font-weight:700\">$text</span>";
}
function row(string $label, string $value, string $status = "info"): string {
    return "<tr><td style=\"padding:6px 12px;font-weight:600;white-space:nowrap\">$label</td>"
         . "<td style=\"padding:6px 12px\">$value</td>"
         . "<td style=\"padding:6px 12px\">" . badge($status, strtoupper($status)) . "</td></tr>";
}
function isValidSqlDate(?string $d): bool {
    return (bool) preg_match("/^\d{4}-\d{2}-\d{2}$/", (string)$d);
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Rent Diagnostic</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:"Segoe UI",sans-serif;background:#0f172a;color:#e2e8f0;padding:24px}
  h1{font-size:24px;margin-bottom:4px;color:#f8fafc}
  .sub{color:#94a3b8;font-size:13px;margin-bottom:24px}
  .card{background:#1e293b;border-radius:12px;padding:20px;margin-bottom:20px}
  .card h2{font-size:16px;margin-bottom:14px;color:#7dd3fc;border-bottom:1px solid #334155;padding-bottom:8px}
  table{width:100%;border-collapse:collapse;font-size:13px}
  tr:nth-child(even) td{background:#1a2744}
  td{vertical-align:top}
  pre{background:#0f172a;border-radius:8px;padding:12px;font-size:12px;overflow-x:auto;color:#a5f3fc;margin-top:8px}
  .alert{padding:10px 14px;border-radius:8px;margin-bottom:10px;font-size:13px}
  .alert-warn{background:#78350f44;border:1px solid #f59e0b}
  .alert-ok{background:#05422044;border:1px solid #10b981}
  .alert-fail{background:#7f1d1d44;border:1px solid #ef4444}
</style>
</head>
<body>
<?php
echo "<h1>&#128269; Rent Invoice Generation &mdash; Diagnostic Report</h1>";
echo "<p class=\"sub\">Generated: ".date("Y-m-d H:i:s T")." &nbsp;|&nbsp; Today: <strong>$today</strong>";
if($tenantId)   echo " &nbsp;|&nbsp; Tenant ID: <strong>$tenantId</strong>";
if($contractId) echo " &nbsp;|&nbsp; Contract ID: <strong>$contractId</strong>";
echo "</p>";

// ─── CHECK 1: Date format ───────────────────────────────────────────────
echo "<div class=\"card\"><h2>&#9989; Check 1 &mdash; Date Format Integrity</h2><table>";
$scope = $contractId ? "AND c.id=$contractId" : ($tenantId ? "AND c.tenant_id=$tenantId" : "");
$cStmt = $db->query("SELECT c.id,c.start_date,c.end_date,c.rent_start_date,c.rent_end_date,t.full_name FROM contracts c LEFT JOIN tenants t ON c.tenant_id=t.id WHERE c.deleted_at IS NULL $scope");
$badDates = [];
foreach($cStmt->fetchAll(PDO::FETCH_ASSOC) as $c){
  foreach(["start_date","end_date","rent_start_date","rent_end_date"] as $f){
    if($c[$f]!==null && !isValidSqlDate($c[$f])){
      $badDates[] = "Contract #{$c["id"]}: $f = {$c[$f]}";
      echo row("Contract #{$c["id"]} $f", htmlspecialchars($c[$f])." &larr; BAD FORMAT","fail");
    }
  }
}
$riScope = $contractId ? "AND ri.contract_id=$contractId" : ($tenantId ? "AND EXISTS(SELECT 1 FROM contracts cc WHERE cc.id=ri.contract_id AND cc.tenant_id=$tenantId)" : "");
$riStmt = $db->query("SELECT ri.id,ri.due_date,ri.period_start,ri.period_end FROM rent_invoices ri WHERE 1=1 $riScope LIMIT 300");
foreach($riStmt->fetchAll(PDO::FETCH_ASSOC) as $r){
  foreach(["due_date","period_start","period_end"] as $f){
    if($r[$f]!==null && !isValidSqlDate($r[$f])){
      $badDates[] = "Invoice #{$r["id"]}: $f = {$r[$f]}";
      echo row("Invoice #{$r["id"]} $f", htmlspecialchars($r[$f])." &larr; BAD FORMAT","fail");
    }
  }
}
if(empty($badDates)) echo row("All date fields","All in correct YYYY-MM-DD format","ok");
echo "</table>";
if(!empty($badDates)) echo "<div class=\"alert alert-fail\" style=\"margin-top:12px\">&#10060; Bad dates found: ".implode(", ",$badDates)."<br>Fix: <code>UPDATE contracts SET start_date=STR_TO_DATE(start_date,'%d/%m/%Y') WHERE start_date REGEXP '^[0-9]{2}/'</code></div>";
else echo "<div class=\"alert alert-ok\" style=\"margin-top:12px\">&#9989; Date format check passed.</div>";
echo "</div>";

// ─── CHECK 2: Cron health ───────────────────────────────────────────────
echo "<div class=\"card\"><h2>&#9200; Check 2 &mdash; CRON / Scheduled Jobs Health</h2>";
try{
  $sjStmt=$db->query("SELECT job_name,status,last_run,duration_seconds,records_processed,error_message FROM scheduled_jobs ORDER BY last_run DESC LIMIT 20");
  $jobs=$sjStmt->fetchAll(PDO::FETCH_ASSOC);
  if($jobs){
    echo "<table><tr style=\"background:#0f172a\"><th style=\"padding:6px 12px;text-align:left\">Job</th><th style=\"padding:6px 12px;text-align:left\">Last Run</th><th style=\"padding:6px 12px;text-align:left\">Status</th><th style=\"padding:6px 12px;text-align:left\">Records</th><th style=\"padding:6px 12px;text-align:left\">Error</th></tr>";
    foreach($jobs as $j){
      $lr=$j["last_run"]??"—";
      $ha=$lr!=="—"?round((time()-strtotime($lr))/3600,1):"?";
      $s=$j["status"]==="Success"?"ok":"fail";
      $stale=is_numeric($ha)&&$ha>26;
      $sb=$stale?"&nbsp;".badge("warn","STALE"):"";
      $err=$j["error_message"]?htmlspecialchars($j["error_message"]):"—";
      echo "<tr><td style=\"padding:6px 12px\">{$j["job_name"]}</td><td style=\"padding:6px 12px\">$lr ({$ha}h ago)$sb</td><td style=\"padding:6px 12px\">".badge($s,$j["status"])."</td><td style=\"padding:6px 12px\">{$j["records_processed"]}</td><td style=\"padding:6px 12px\">$err</td></tr>";
    }
    echo "</table>";
  } else {
    echo "<div class=\"alert alert-warn\">&#9888; No rows in <code>scheduled_jobs</code> &mdash; cron has never logged or table is missing.</div>";
  }
} catch(Exception $e){
  echo "<div class=\"alert alert-fail\">&#10060; <code>scheduled_jobs</code> query failed: ".htmlspecialchars($e->getMessage())."</div>";
}
$logPaths=[ini_get("error_log"),"C:/xampp/php/logs/php_error_log","C:/xampp/apache/logs/error.log"];
foreach($logPaths as $lp){
  if($lp&&file_exists($lp)){
    $lines=file($lp,FILE_IGNORE_NEW_LINES);
    $recent=array_filter($lines,fn($l)=>str_contains($l,date("Y-m-d"))||str_contains($l,date("d-M-Y")));
    $recent=array_slice(array_values($recent),-30);
    echo "<p style=\"margin-top:12px;color:#94a3b8;font-size:12px\">PHP log: <code>".htmlspecialchars($lp)."</code></p>";
    echo "<pre>".(empty($recent)?"(no entries for today)":htmlspecialchars(implode("\n",$recent)))."</pre>";
    break;
  }
}
echo "</div>";

// ─── CHECK 3: Blocking invoices ────────────────────────────────────────
echo "<div class=\"card\"><h2>&#128274; Check 3 &mdash; Unpaid Invoice Blocking</h2>";
$scope3=$contractId?"AND c.id=$contractId":($tenantId?"AND c.tenant_id=$tenantId":"");
$bStmt=$db->query("SELECT c.id as cid,t.full_name,a.code,b.name as bname,ri.id as rid,ri.invoice_number,ri.due_date,ri.period_start,ri.period_end,ri.status as rstatus,ri.amount FROM contracts c JOIN tenants t ON c.tenant_id=t.id JOIN apartments a ON c.apartment_id=a.id JOIN buildings b ON a.building_id=b.id LEFT JOIN rent_invoices ri ON ri.contract_id=c.id WHERE c.status IN('Active','Approved') $scope3 ORDER BY c.id,ri.due_date DESC");
$rows=$bStmt->fetchAll(PDO::FETCH_ASSOC);
$grouped=[];foreach($rows as $r)$grouped[$r["cid"]][]=$r;
if(empty($grouped)){echo "<div class=\"alert alert-warn\">&#9888; No active contracts found.</div>";}
else{
  echo "<table><tr style=\"background:#0f172a\"><th style=\"padding:6px 12px;text-align:left\">Contract/Tenant</th><th style=\"padding:6px 12px;text-align:left\">Latest Invoice</th><th style=\"padding:6px 12px;text-align:left\">Due Date</th><th style=\"padding:6px 12px;text-align:left\">Status</th><th style=\"padding:6px 12px;text-align:left\">Next Period</th></tr>";
  foreach($grouped as $cid=>$invs){
    $fi=$invs[0];$li=$invs[0];$nil=$li["rid"]===null;
    $isb=!$nil&&in_array($li["rstatus"],["Unpaid","Partial"])&&$li["due_date"]<$today;
    $sb=$isb?"&nbsp;".badge("fail","BLOCKING"):"";
    $ns="—";
    if(!$nil&&isValidSqlDate($li["period_end"]))$ns=date("Y-m-d",strtotime($li["period_end"]." +1 day"));
    elseif(!$nil&&isValidSqlDate($li["due_date"]))$ns=date("Y-m-d",strtotime($li["due_date"]." +1 month"));
    $ib=$nil?badge("warn","NO INVOICES"):($li["rstatus"]==="Paid"?badge("ok","PAID"):($li["rstatus"]==="Partial"?badge("warn","PARTIAL"):badge("fail","UNPAID")));
    echo "<tr><td style=\"padding:6px 12px\"><strong>#$cid</strong> {$fi["full_name"]}<br><span style=\"color:#94a3b8;font-size:11px\">{$fi["bname"]} - {$fi["code"]}</span></td><td style=\"padding:6px 12px\">".($nil?"—":htmlspecialchars($li["invoice_number"]))."</td><td style=\"padding:6px 12px\">".htmlspecialchars($li["due_date"]??"—")."</td><td style=\"padding:6px 12px\">$ib $sb</td><td style=\"padding:6px 12px\">$ns</td></tr>";
  }
  echo "</table>";
}
echo "<div class=\"alert alert-warn\" style=\"margin-top:12px\">&#8505;&#65039; <strong>generateInvoices() skip logic:</strong> if the latest invoice's <code>period_end</code> &gt; today+7, the loop skips that contract entirely regardless of payment status.</div></div>";

// ─── CHECK 4: Contract status ────────────────────────────────────────
echo "<div class=\"card\"><h2>&#128203; Check 4 &mdash; Contract &amp; Tenant Status</h2>";
$scope4=$contractId?"AND c.id=$contractId":($tenantId?"AND c.tenant_id=$tenantId":"");
$sStmt=$db->query("SELECT c.id as cid,t.id as tid,t.full_name,t.status as tstatus,a.code,b.name as bname,c.status as cstatus,c.rent_status,c.start_date,c.end_date,c.rent_start_date,c.rent_end_date,c.monthly_rent,c.deleted_at FROM contracts c JOIN tenants t ON c.tenant_id=t.id JOIN apartments a ON c.apartment_id=a.id JOIN buildings b ON a.building_id=b.id WHERE 1=1 $scope4 ORDER BY c.id DESC LIMIT 50");
foreach($sStmt->fetchAll(PDO::FETCH_ASSOC) as $s){
  $issues=[];
  if($s["deleted_at"]) $issues[]="Soft-deleted (deleted_at={$s["deleted_at"]})";
  if(!in_array($s["cstatus"],["Active","Approved"])) $issues[]="contract.status=<strong>{$s["cstatus"]}</strong>";
  if($s["rent_status"]!=="Active") $issues[]="rent_status=<strong>{$s["rent_status"]}</strong> (must be Active)";
  if(!isValidSqlDate($s["start_date"])) $issues[]="start_date bad: {$s["start_date"]}";
  if(!isValidSqlDate($s["end_date"]))   $issues[]="end_date bad: {$s["end_date"]}";
  if(isValidSqlDate($s["end_date"])&&$s["end_date"]<$today) $issues[]="end_date {$s["end_date"]} is in the past";
  if((float)$s["monthly_rent"]==0) $issues[]="monthly_rent is 0";
  $os=empty($issues)?"ok":(in_array($s["cstatus"],["Active","Approved"])?"warn":"fail");
  $hc=$os==="ok"?"#2ecc71":($os==="warn"?"#f39c12":"#e74c3c");
  echo "<div style=\"border:1px solid $hc;border-radius:8px;padding:14px;margin-bottom:14px\">";
  echo "<div style=\"display:flex;justify-content:space-between;align-items:center;margin-bottom:10px\"><strong>Contract #{$s["cid"]} &mdash; {$s["full_name"]}</strong>&nbsp;<span style=\"color:#94a3b8\">{$s["bname"]} / {$s["code"]}</span>&nbsp;&nbsp;".badge($os,$os==="ok"?"&#10004; ELIGIBLE":"&#10008; ISSUE")."</div>";
  echo "<table>".row("Tenant status",htmlspecialchars($s["tstatus"]??"—"),$s["tstatus"]==="Active"?"ok":"warn").row("Contract status",htmlspecialchars($s["cstatus"]),in_array($s["cstatus"],["Active","Approved"])?"ok":"fail").row("Rent status",htmlspecialchars($s["rent_status"]??"—"),$s["rent_status"]==="Active"?"ok":"fail").row("start_date",htmlspecialchars($s["start_date"]??"—"),isValidSqlDate($s["start_date"])?"ok":"fail").row("end_date",htmlspecialchars($s["end_date"]??"—"),(isValidSqlDate($s["end_date"])&&$s["end_date"]>=$today)?"ok":"fail").row("monthly_rent",number_format((float)$s["monthly_rent"],2),(float)$s["monthly_rent"]>0?"ok":"warn").row("deleted_at",htmlspecialchars($s["deleted_at"]??"NULL"),!$s["deleted_at"]?"ok":"fail")."</table>";
  if(!empty($issues)) echo "<div class=\"alert alert-fail\" style=\"margin-top:10px\">&#10060; ".implode(" | ",$issues)."</div>";
  echo "</div>";
}
echo "</div>";

// ─── SIMULATION ─────────────────────────────────────────────────────────
$scope5=$contractId?"AND c.id=$contractId":($tenantId?"AND c.tenant_id=$tenantId":"");
$simStmt=$db->query("SELECT c.id as cid,a.monthly_rent,c.start_date,c.end_date FROM contracts c JOIN apartments a ON c.apartment_id=a.id WHERE c.status IN('Active','Approved') AND c.rent_status='Active' $scope5");
$simC=$simStmt->fetchAll(PDO::FETCH_ASSOC);
$targetDate=date("Y-m-d",strtotime("+7 days"));
echo "<div class=\"card\"><h2>&#129514; Simulation &mdash; What generateInvoices() Would Process Now</h2>";
if(empty($simC)){
  echo "<div class=\"alert alert-fail\">&#10060; Query returns 0 rows. generateInvoices() would produce nothing. Root cause: no contract has status IN('Active','Approved') AND rent_status='Active'.</div>";
} else {
  $wg=0;
  echo "<div class=\"alert alert-ok\">&#9989; ".count($simC)." contract(s) visible to generateInvoices().</div>";
  echo "<table style=\"margin-top:10px\"><tr style=\"background:#0f172a\"><th style=\"padding:6px 12px;text-align:left\">Contract</th><th style=\"padding:6px 12px;text-align:left\">Last period_end</th><th style=\"padding:6px 12px;text-align:left\">Next start</th><th style=\"padding:6px 12px;text-align:left\">Contract end</th><th style=\"padding:6px 12px;text-align:left\">Would generate?</th></tr>";
  foreach($simC as $sc){
    $i2=$db->prepare("SELECT period_end FROM rent_invoices WHERE contract_id=? ORDER BY period_end DESC LIMIT 1");
    $i2->execute([$sc["cid"]]);$li=$i2->fetch(PDO::FETCH_ASSOC);
    $ns=$li&&$li["period_end"]?date("Y-m-d",strtotime($li["period_end"]." +1 day")):$sc["start_date"];
    $ed=$sc["end_date"];
    $we=isValidSqlDate($ns)&&isValidSqlDate($ed)&&$ns<$ed&&$ns<=$targetDate;
    if($we)$wg++;
    echo "<tr><td style=\"padding:6px 12px\">#{$sc["cid"]}</td><td style=\"padding:6px 12px\">".($li?htmlspecialchars($li["period_end"]):"(none)")."</td><td style=\"padding:6px 12px\">".htmlspecialchars($ns??"—")."</td><td style=\"padding:6px 12px\">".htmlspecialchars($ed??"—")."</td><td style=\"padding:6px 12px\">".($we?badge("ok","YES"):badge("fail","NO – SKIPPED"))."</td></tr>";
  }
  echo "</table><p style=\"margin-top:10px;color:#94a3b8\">Would generate: <strong>$wg / ".count($simC)."</strong> (window: today &rarr; $targetDate)</p>";
}
echo "</div>";
?>
<div class="card" style="border:1px solid #334155">
<h2>&#128204; Quick Fix Commands</h2>
<table>
<tr><td style="padding:6px 12px;font-weight:600">Fix bad date format</td><td style="padding:6px 12px"><code>UPDATE contracts SET start_date=STR_TO_DATE(start_date,'%d/%m/%Y') WHERE start_date REGEXP '^[0-9]{2}/';</code></td></tr>
<tr><td style="padding:6px 12px;font-weight:600">Activate rent_status</td><td style="padding:6px 12px"><code>UPDATE contracts SET rent_status='Active' WHERE status IN('Active','Approved') AND rent_status!='Active';</code></td></tr>
<tr><td style="padding:6px 12px;font-weight:600">Trigger generation</td><td style="padding:6px 12px"><a href="/Bitar/backend/generate_invoices.php" style="color:#7dd3fc">/Bitar/backend/generate_invoices.php</a></td></tr>
<tr><td style="padding:6px 12px;font-weight:600">Check cron log</td><td style="padding:6px 12px"><code>SELECT * FROM scheduled_jobs ORDER BY last_run DESC LIMIT 10;</code></td></tr>
<tr><td style="padding:6px 12px;font-weight:600">Scope to tenant</td><td style="padding:6px 12px"><code>?tenant_id=XX</code> or <code>?contract_id=XX</code></td></tr>
</table>
</div>
</body></html>
