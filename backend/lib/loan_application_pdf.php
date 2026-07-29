<?php
// Builds the Loan Application PDF, mirroring the React LoanApplicationForm layout
// (letterhead, applicant grid + photo, loan-details grid, declaration, three
// signature boxes, footer). Pure data-in → PDF-bytes-out; all values come from
// the database rows passed in.

require_once __DIR__ . '/Pdf.php';

/** UTF-8 → WinAnsi (CP1252) so accented Latin renders; unmappable chars dropped. */
function la_w(?string $s): string
{
    $s = (string)$s;
    $conv = @iconv('UTF-8', 'CP1252//TRANSLIT//IGNORE', $s);
    return $conv === false ? $s : $conv;
}

/** Indian-grouped rupees, e.g. 100000 → "Rs. 1,00,000". */
function la_money($n): string
{
    $n = (float)$n;
    $neg = $n < 0; $n = abs($n);
    $s = number_format($n, 0, '.', '');
    $last3 = substr($s, -3);
    $rest = strlen($s) > 3 ? substr($s, 0, -3) : '';
    if ($rest !== '') {
        $rest = preg_replace('/\B(?=(\d{2})+(?!\d))/', ',', $rest);
        $last3 = ',' . $last3;
    }
    return 'Rs. ' . ($neg ? '-' : '') . $rest . $last3;
}

function la_date(?string $d): string
{
    if (!$d) return '-';
    $t = strtotime($d);
    return $t ? date('d M Y', $t) : (string)$d;
}

/** One labelled field with a dashed underline, matching the React InfoRow. */
function la_field(Pdf $pdf, float $x, float $y, float $w, string $label, string $value): void
{
    $pdf->setFont('B', 6.8);
    $pdf->text($x, $y, la_w(strtoupper($label)), [150, 150, 150]);
    $pdf->setFont('', 9.5);
    $val = $value === '' ? '-' : $value;
    $pdf->text($x, $y + 5, la_w($val), [55, 55, 55]);
    $pdf->dashedLine($x, $y + 6.6, $x + $w, $y + 6.6);
}

/** @return string PDF bytes */
function build_loan_application_pdf(array $loan, ?array $customer, array $company): string
{
    $pdf = new Pdf();

    $L = 15.0; $R = 195.0;              // page content margins (mm)
    $name    = $company['company_name'] ?: 'RR Groups';
    $address = $company['address'] ?: '';
    $phone   = $company['contact_number'] ?: '';
    $gst     = $company['gst_number'] ?: '';

    // ── Header ──
    $pdf->circleFilled(23, 22, 8, [168, 118, 21]);           // gold monogram
    $pdf->setFont('B', 13);
    $pdf->textCenter(23, 25, 'RR', [255, 255, 255]);
    $pdf->setFont('B', 16);
    $pdf->text(35, 20, la_w($name), [20, 20, 20]);
    $pdf->setFont('', 8);
    if ($address) $pdf->text(35, 25.5, la_w($address), [110, 110, 110]);
    $metaBits = [];
    if ($phone) $metaBits[] = 'Ph: ' . $phone;
    if ($gst)   $metaBits[] = 'GST: ' . $gst;
    if ($metaBits) $pdf->text(35, 30, la_w(implode('  -  ', $metaBits)), [110, 110, 110]);

    $pdf->setFont('B', 12);
    $pdf->textRight($R, 19, 'LOAN APPLICATION', [150, 100, 20]);
    $pdf->setFont('', 8);
    $pdf->textRight($R, 24.5, 'Ref: ' . la_w($loan['loan_number'] ?? ''), [110, 110, 110]);
    $pdf->textRight($R, 29, 'Date: ' . la_date($loan['start_date'] ?? null), [110, 110, 110]);

    $pdf->setLineWidth(0.6);
    $pdf->line($L, 34, $R, 34, [40, 40, 40]);

    // ── Applicant + photo ──
    $colW = 68.0;
    la_field($pdf, $L, 44, $colW, 'Full Name', (string)($customer['full_name'] ?? $loan['customer_name'] ?? ''));
    la_field($pdf, 88, 44, $colW, 'Mobile', (string)($customer['mobile'] ?? ''));
    la_field($pdf, $L, 58, $colW, 'Address', (string)($customer['address'] ?? ''));
    la_field($pdf, 88, 58, $colW, 'Occupation', (string)($customer['occupation'] ?? ''));
    la_field($pdf, $L, 72, $colW, 'Aadhaar Number', (string)($customer['aadhaar'] ?? ''));
    la_field($pdf, 88, 72, $colW, 'PAN Number', (string)($customer['pan'] ?? ''));

    // Photo box (top-right).
    $px = 167.0; $py = 42.0; $pw = 28.0; $pht = 32.0;
    $placed = false;
    $photo = $customer['photo_url'] ?? '';
    if (is_string($photo) && strpos($photo, 'data:image/jpeg') === 0) {
        $b64 = substr($photo, strpos($photo, ',') + 1);
        $raw = base64_decode($b64, true);
        if ($raw !== false) $placed = $pdf->image($px, $py, $pw, $pht, $raw);
    }
    if (!$placed) {
        $pdf->rect($px, $py, $pw, $pht, 'D', [170, 170, 170], [255, 255, 255], true);
        $pdf->setFont('B', 7.5);
        $pdf->textCenter($px + $pw / 2, $py + $pht / 2, 'Affix Photo', [150, 150, 150]);
    }
    $pdf->setFont('B', 6.5);
    $pdf->textCenter($px + $pw / 2, $py + $pht + 4, 'APPLICANT PHOTO', [150, 150, 150]);

    $pdf->dashedLine($L, 86, $R, 86);

    // ── Loan details ──
    $pdf->setFont('B', 8);
    $pdf->text($L, 93, 'LOAN DETAILS', [110, 110, 110]);

    $type = $loan['loan_type'] ?? 'monthly';
    $typeLabel = $type === 'weekly' ? 'Weekly Collection - 10 Weeks' : ($type === 'daily' ? 'Daily Collection' : 'Monthly EMI');
    $instLabel = $type === 'weekly' ? 'Weekly Installment' : ($type === 'daily' ? 'Daily Installment' : 'Monthly EMI');

    $fields = [
        ['Loan Number', (string)($loan['loan_number'] ?? '')],
        ['Collection Type', $typeLabel],
        ['Loan Amount', la_money($loan['loan_amount'] ?? 0)],
        ['Interest Rate', ($loan['interest_percentage'] ?? 0) . '%'],
    ];
    if ($type === 'weekly') {
        $fields[] = ['Duration', '10 Weeks'];
        $fields[] = ['Upfront Interest', la_money($loan['total_interest'] ?? 0)];
        $fields[] = ['Disbursed Amount', la_money(($loan['loan_amount'] ?? 0) - ($loan['total_interest'] ?? 0))];
    } elseif ($type === 'daily') {
        $fields[] = ['Duration', ($loan['loan_duration'] ?? 0) . ' Days'];
        $fields[] = ['Total Interest', la_money($loan['total_interest'] ?? 0)];
        $fields[] = ['Total Repayment', la_money($loan['total_repayment'] ?? 0)];
    } else {
        $fields[] = ['Duration', ($loan['loan_duration'] ?? 0) . ' Months'];
        $fields[] = ['Total Interest', la_money($loan['total_interest'] ?? 0)];
        $fields[] = ['Total Repayment', la_money($loan['total_repayment'] ?? 0)];
    }
    $fields[] = [$instLabel, la_money($loan['emi'] ?? 0)];
    $fields[] = ['Start Date', la_date($loan['start_date'] ?? null)];
    $fields[] = ['Processing Fee', la_money($loan['processing_fee'] ?? 0)];
    $fields[] = ['Assigned Agent', (string)($loan['agent_name'] ?? '')];

    $cols = [$L, 75.0, 135.0];
    $cw = 52.0;
    $y0 = 101.0; $rh = 13.0;
    foreach ($fields as $i => $f) {
        $x = $cols[$i % 3];
        $y = $y0 + intdiv($i, 3) * $rh;
        la_field($pdf, $x, $y, $cw, $f[0], $f[1]);
    }

    $pdf->dashedLine($L, 152, $R, 152);

    // ── Declaration ──
    $pdf->setFont('B', 8);
    $pdf->text($L, 159, 'DECLARATION', [110, 110, 110]);
    $decl = 'I, the undersigned, hereby declare that all the information provided above is true and correct '
        . 'to the best of my knowledge. I agree to repay the loan amount along with applicable interest as per '
        . 'the agreed schedule. I understand that failure to repay on time may attract additional charges and '
        . 'legal action as per applicable laws.';
    $pdf->setFont('', 9);
    $y = 165.0;
    foreach (la_wrap($pdf, $decl, $R - $L, 9) as $line) {
        $pdf->text($L, $y, la_w($line), [90, 90, 90]);
        $y += 4.6;
    }

    // ── Signatures ──
    $boxes = [['Borrower Signature', 15.0], ['Guarantor Signature', 78.0], ['Authorised Signatory', 141.0]];
    $bw = 54.0; $bh = 16.0; $by = 192.0;
    foreach ($boxes as [$lbl, $bx]) {
        $pdf->rect($bx, $by, $bw, $bh, 'D', [150, 150, 150], [255, 255, 255], true);
        $pdf->setFont('B', 8);
        $pdf->textCenter($bx + $bw / 2, $by + $bh + 5, la_w($lbl), [110, 110, 110]);
    }

    // ── Footer ──
    $pdf->dashedLine($L, 228, $R, 228, 1, 1, [200, 200, 200]);
    $pdf->setFont('', 7.5);
    $foot = 'This is a computer-generated application form.  -  ' . $name . ($address ? '  -  ' . $address : '');
    $pdf->textCenter((($L + $R) / 2), 233, la_w($foot), [150, 150, 150]);

    return $pdf->output();
}

/** Greedy word-wrap using the PDF's own font metrics. @return string[] */
function la_wrap(Pdf $pdf, string $text, float $maxW, float $size): array
{
    $pdf->setFont('', $size);
    $words = preg_split('/\s+/', trim($text));
    $lines = []; $cur = '';
    foreach ($words as $wd) {
        $try = $cur === '' ? $wd : "$cur $wd";
        if ($pdf->stringWidth(la_w($try)) > $maxW && $cur !== '') {
            $lines[] = $cur; $cur = $wd;
        } else {
            $cur = $try;
        }
    }
    if ($cur !== '') $lines[] = $cur;
    return $lines;
}
