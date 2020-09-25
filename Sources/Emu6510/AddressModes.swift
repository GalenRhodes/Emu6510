/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: AddressModes.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/24/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//************************************************************************/

import Foundation

public enum AddressModes: String {
    case ABS  = "Absolute"
    case ABSX = "AbsoluteX"
    case ABSY = "AbsoluteY"
    case ACC  = "Accumulator"
    case IMM  = "Immediate"
    case IMP  = "Implied"
    case IND  = "Indirect"
    case INDX = "IndirectX"
    case INDY = "IndirectY"
    case REL  = "Relative"
    case ZP   = "ZeroPage"
    case ZPX  = "ZeroPageX"
    case ZPY  = "ZeroPageY"
}
