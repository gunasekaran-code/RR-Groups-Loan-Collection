<?php
// Minimal, dependency-free PDF writer (A4, millimetre units, top-left origin).
// Supports base-14 Helvetica text with accurate widths, solid & dashed lines,
// stroked/filled rectangles, filled circles, and embedded JPEG images — enough
// to render a one-page letterhead document server-side without FPDF/Composer.

class Pdf
{
    private float $k = 2.834645669;      // millimetres → PDF points
    private float $pw = 210.0;           // page width  (mm) — A4
    private float $ph = 297.0;           // page height (mm) — A4
    private string $buf = '';            // content stream operators
    /** @var array<int,array{data:string,w:int,h:int,cs:string}> */
    private array $images = [];
    private array $wHelv;                // Helvetica char widths (per 1000)
    private array $wBold;                // Helvetica-Bold char widths
    private string $font = 'F1';         // current font resource
    private float $size = 10.0;          // current font size (pt)

    public function __construct()
    {
        $helv = '278 278 355 556 556 889 667 191 333 333 389 584 278 333 278 278 556 556 556 556 556 556 556 556 556 556 278 278 584 584 584 556 1015 667 667 722 722 667 611 778 722 278 500 667 556 833 722 778 667 778 722 667 611 722 667 944 667 667 611 278 278 278 469 556 333 556 556 500 556 556 278 556 556 222 222 500 222 833 556 556 556 556 333 500 278 556 500 722 500 500 500 334 260 334 584';
        $bold = '278 333 474 556 556 889 722 238 333 333 389 584 278 333 278 278 556 556 556 556 556 556 556 556 556 556 333 333 584 584 584 611 975 722 722 722 722 667 611 778 722 278 556 722 611 833 722 778 667 778 722 667 611 722 667 944 667 667 611 333 278 333 584 556 333 556 611 556 611 556 333 611 611 278 278 556 278 889 611 611 611 611 389 556 333 611 556 778 556 556 500 389 280 389 584';
        $this->wHelv = array_map('intval', explode(' ', $helv));
        $this->wBold = array_map('intval', explode(' ', $bold));
    }

    // ── coordinate helpers (mm → points, top-left origin) ──
    private function px(float $x): float { return $x * $this->k; }
    private function py(float $y): float { return ($this->ph - $y) * $this->k; }
    private static function fmt(float $n): string { return rtrim(rtrim(number_format($n, 3, '.', ''), '0'), '.'); }

    public function setFont(string $style = '', float $size = 10): void
    {
        $this->font = strtoupper($style) === 'B' ? 'F2' : 'F1';
        $this->size = $size;
    }

    /** Width of a string in the current font/size, in millimetres. */
    public function stringWidth(string $s): float
    {
        $tbl = $this->font === 'F2' ? $this->wBold : $this->wHelv;
        $w = 0;
        $len = strlen($s);
        for ($i = 0; $i < $len; $i++) {
            $c = ord($s[$i]);
            $w += ($c >= 32 && $c <= 126) ? $tbl[$c - 32] : 556;
        }
        return ($w / 1000) * $this->size / $this->k;
    }

    private static function esc(string $s): string
    {
        return str_replace(['\\', '(', ')', "\r"], ['\\\\', '\\(', '\\)', ''], $s);
    }

    private function col(array $rgb, bool $stroke): string
    {
        [$r, $g, $b] = $rgb;
        $op = $stroke ? 'RG' : 'rg';
        return self::fmt($r / 255) . ' ' . self::fmt($g / 255) . ' ' . self::fmt($b / 255) . " $op\n";
    }

    /** Draw text with its baseline at (x, y) mm from the top-left. */
    public function text(float $x, float $y, string $s, array $rgb = [40, 40, 40]): void
    {
        $this->buf .= "BT\n" . $this->col($rgb, false) . "/{$this->font} " . self::fmt($this->size) . " Tf\n"
            . self::fmt($this->px($x)) . ' ' . self::fmt($this->py($y)) . " Td (" . self::esc($s) . ") Tj\nET\n";
    }

    public function textRight(float $xRight, float $y, string $s, array $rgb = [40, 40, 40]): void
    {
        $this->text($xRight - $this->stringWidth($s), $y, $s, $rgb);
    }

    public function textCenter(float $xCenter, float $y, string $s, array $rgb = [40, 40, 40]): void
    {
        $this->text($xCenter - $this->stringWidth($s) / 2, $y, $s, $rgb);
    }

    public function setLineWidth(float $mm): void { $this->buf .= self::fmt($mm * $this->k) . " w\n"; }

    public function line(float $x1, float $y1, float $x2, float $y2, array $rgb = [120, 120, 120]): void
    {
        $this->buf .= $this->col($rgb, true)
            . self::fmt($this->px($x1)) . ' ' . self::fmt($this->py($y1)) . " m "
            . self::fmt($this->px($x2)) . ' ' . self::fmt($this->py($y2)) . " l S\n";
    }

    public function dashedLine(float $x1, float $y1, float $x2, float $y2, float $on = 1.2, float $off = 1.2, array $rgb = [170, 170, 170]): void
    {
        $this->buf .= '[' . self::fmt($on * $this->k) . ' ' . self::fmt($off * $this->k) . "] 0 d\n";
        $this->line($x1, $y1, $x2, $y2, $rgb);
        $this->buf .= "[] 0 d\n";
    }

    /** style: 'D' stroke, 'F' fill, 'DF' both. */
    public function rect(float $x, float $y, float $w, float $h, string $style = 'D', array $stroke = [150, 150, 150], array $fill = [255, 255, 255], bool $dashed = false): void
    {
        if (strpos($style, 'F') !== false) $this->buf .= $this->col($fill, false);
        if (strpos($style, 'D') !== false) $this->buf .= $this->col($stroke, true);
        if ($dashed) $this->buf .= '[' . self::fmt(1.2 * $this->k) . ' ' . self::fmt(1.2 * $this->k) . "] 0 d\n";
        $op = $style === 'F' ? 'f' : ($style === 'DF' || $style === 'FD' ? 'B' : 'S');
        $this->buf .= self::fmt($this->px($x)) . ' ' . self::fmt($this->py($y + $h)) . ' '
            . self::fmt($w * $this->k) . ' ' . self::fmt($h * $this->k) . " re $op\n";
        if ($dashed) $this->buf .= "[] 0 d\n";
    }

    public function circleFilled(float $cx, float $cy, float $r, array $rgb): void
    {
        $kap = 0.5522847498 * $r;
        $x = $this->px($cx); $y = $this->py($cy); $rk = $r * $this->k; $kk = $kap * $this->k;
        $this->buf .= $this->col($rgb, false)
            . self::fmt($x + $rk) . ' ' . self::fmt($y) . " m\n"
            . self::fmt($x + $rk) . ' ' . self::fmt($y + $kk) . ' ' . self::fmt($x + $kk) . ' ' . self::fmt($y + $rk) . ' ' . self::fmt($x) . ' ' . self::fmt($y + $rk) . " c\n"
            . self::fmt($x - $kk) . ' ' . self::fmt($y + $rk) . ' ' . self::fmt($x - $rk) . ' ' . self::fmt($y + $kk) . ' ' . self::fmt($x - $rk) . ' ' . self::fmt($y) . " c\n"
            . self::fmt($x - $rk) . ' ' . self::fmt($y - $kk) . ' ' . self::fmt($x - $kk) . ' ' . self::fmt($y - $rk) . ' ' . self::fmt($x) . ' ' . self::fmt($y - $rk) . " c\n"
            . self::fmt($x + $kk) . ' ' . self::fmt($y - $rk) . ' ' . self::fmt($x + $rk) . ' ' . self::fmt($y - $kk) . ' ' . self::fmt($x + $rk) . ' ' . self::fmt($y) . " c\nf\n";
    }

    /** Place a JPEG image (raw bytes) in the box (x,y,w,h) mm. Returns false if not a usable JPEG. */
    public function image(float $x, float $y, float $w, float $h, string $jpeg): bool
    {
        $info = self::parseJpeg($jpeg);
        if (!$info) return false;
        $idx = count($this->images) + 1;
        $this->images[$idx] = ['data' => $jpeg, 'w' => $info['w'], 'h' => $info['h'], 'cs' => $info['cs']];
        $this->buf .= "q\n" . self::fmt($w * $this->k) . ' 0 0 ' . self::fmt($h * $this->k) . ' '
            . self::fmt($this->px($x)) . ' ' . self::fmt($this->py($y + $h)) . " cm\n/Img$idx Do\nQ\n";
        return true;
    }

    /** @return array{w:int,h:int,cs:string}|null */
    private static function parseJpeg(string $d): ?array
    {
        if (strlen($d) < 4 || substr($d, 0, 2) !== "\xFF\xD8") return null;
        $i = 2; $len = strlen($d);
        while ($i < $len) {
            if (ord($d[$i]) !== 0xFF) { $i++; continue; }
            $marker = ord($d[$i + 1]); $i += 2;
            if ($marker === 0xD8 || $marker === 0xD9) continue;
            if ($marker >= 0xD0 && $marker <= 0xD7) continue;
            $seglen = (ord($d[$i]) << 8) + ord($d[$i + 1]);
            if (($marker >= 0xC0 && $marker <= 0xCF) && $marker !== 0xC4 && $marker !== 0xC8 && $marker !== 0xCC) {
                $h = (ord($d[$i + 3]) << 8) + ord($d[$i + 4]);
                $w = (ord($d[$i + 5]) << 8) + ord($d[$i + 6]);
                $comp = ord($d[$i + 7]);
                $cs = $comp === 1 ? 'DeviceGray' : ($comp === 4 ? 'DeviceCMYK' : 'DeviceRGB');
                return ['w' => $w, 'h' => $h, 'cs' => $cs];
            }
            $i += $seglen;
        }
        return null;
    }

    public function output(): string
    {
        $objs = [];
        $objs[1] = "<< /Type /Catalog /Pages 2 0 R >>";
        $objs[2] = "<< /Type /Pages /Kids [3 0 R] /Count 1 >>";

        $xobj = '';
        foreach ($this->images as $idx => $_) $xobj .= "/Img$idx " . (6 + $idx) . " 0 R ";
        $res = "<< /Font << /F1 4 0 R /F2 5 0 R >>" . ($xobj ? " /XObject << $xobj>>" : '') . " >>";
        $mediabox = '0 0 ' . self::fmt($this->pw * $this->k) . ' ' . self::fmt($this->ph * $this->k);
        $objs[3] = "<< /Type /Page /Parent 2 0 R /MediaBox [$mediabox] /Resources $res /Contents 6 0 R >>";
        $objs[4] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>";
        $objs[5] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>";
        $objs[6] = "<< /Length " . strlen($this->buf) . " >>\nstream\n" . $this->buf . "\nendstream";
        foreach ($this->images as $idx => $img) {
            $objs[6 + $idx] = "<< /Type /XObject /Subtype /Image /Width {$img['w']} /Height {$img['h']} "
                . "/ColorSpace /{$img['cs']} /BitsPerComponent 8 /Filter /DCTDecode /Length " . strlen($img['data']) . " >>\nstream\n"
                . $img['data'] . "\nendstream";
        }

        $out = "%PDF-1.4\n";
        $offsets = [];
        ksort($objs);
        foreach ($objs as $n => $body) {
            $offsets[$n] = strlen($out);
            $out .= "$n 0 obj\n$body\nendobj\n";
        }
        $count = count($objs);
        $xrefPos = strlen($out);
        $out .= "xref\n0 " . ($count + 1) . "\n0000000000 65535 f \n";
        for ($n = 1; $n <= $count; $n++) {
            $out .= sprintf("%010d 00000 n \n", $offsets[$n]);
        }
        $out .= "trailer\n<< /Size " . ($count + 1) . " /Root 1 0 R >>\nstartxref\n$xrefPos\n%%EOF";
        return $out;
    }
}
