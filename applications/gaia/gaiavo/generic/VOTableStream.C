/*+
 *  Name:
 *     gaia::VOTableStream

 *  Purpose:
 *     Class for handling VOTable BINARY and BINARY2 streams.

 *  Language:
 *     C++

 *  Copyright:
 *     Copyright (C) 2008-2014 Science and Technology Facilities Council.
 *     All Rights Reserved.

 *  Licence:
 *     This program is free software; you can redistribute it and/or
 *     modify it under the terms of the GNU General Public License as
 *     published by the Free Software Foundation; either version 2 of the
 *     License, or (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be
 *     useful, but WITHOUT ANY WARRANTY; without even the implied warranty
 *     of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program; if not, write to the Free Software
 *     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
 *     02110-1301, USA

 *  Authors:
 *     PWD: Peter W. Draper (JAC, Durham University)

 *  History:
 *     13-JUN-2008 (PWD):
 *        Original version.
 *     {enter_changes_here}
 *-
 */

#if HAVE_CONFIG_H
#include "config.h"
#endif

/*  System includes. */
#include <iostream>
#include <streambuf>
#include <memory>
#include <bitset>
#include <cmath>
#include <cstdio>
#include <cstdlib>

/*  Local includes. */
#include "VOTableStream.h"
#include "GaiaUtils.h"

using namespace std;

namespace gaia {

    /**
     *  Constructor, creates an instance.
     */
    VOTableStream::VOTableStream( streambuf *in ) :
        in_( in )
    {
        //  Check if BIGENDIAN. XXX autoconf this.
        union {
            short s;
            char b[2];
        } u;
        u.s = 1;
        if ( u.b[0] != 0 ) {
            bigendian_ = false;
        }
        else {
            bigendian_ = true;
        }

        //  Check for size of 64bit integer. XXX autoconf this.
        if ( sizeof( long ) == 4 ) {
            uselonglong_ = true;
        }
        else {
            uselonglong_ = false;
        }
    }

    /**
     *  Destructor.
     */
    VOTableStream::~VOTableStream()
    {
        //  Do nothing.
    }

    /**
     *  Read a supported vector of data objects from the input stream and
     *  write their formatted values to the given output stream. Returns false
     *  if the read fails. If an explicit null value is defined for this
     *  type then that should be given in the string form.
     */
    bool VOTableStream::readPrint( datatype type, int quantity,
                                   bool havenull, string &nullstring,
                                   ostream *out )
    {
        switch ( type ) {
            case BOOLEAN: {
                return readBooleans( quantity, out );
            }
            break;
            case BITARRAY: {
                return readBitArrays( quantity, out );
            }
            break;
            case BYTE: {
                return readBytes( quantity, havenull, nullstring, out );
            }
            break;
            case CHAR: {
                return readChars( quantity, out );
            }
            break;
            case UNICODE: {
                return readUniChars( quantity, out );
            }
            break;
            case SHORT: {
                return readValues<short>( quantity, havenull, nullstring,
                                          out );
            }
            break;
            case INT: {
                return readValues<int>( quantity, havenull, nullstring, out );
            }
            break;
            case LONG: {
                if ( uselonglong_ ) {
                    return readValues<long long>( quantity, havenull,
                                                  nullstring, out );
                }
                else {
                    return readValues<long>( quantity, havenull,
                                             nullstring, out );
                }
            }
            break;
            case FLOAT: {
                return readFloatValues<float>( quantity, havenull, nullstring,
                                               out );
            }
            break;
            case DOUBLE: {
                return readFloatValues<double>( quantity, havenull,
                                                nullstring, out );
            }
            break;
            case FLOATCOMPLEX: {
                return readFloatValues<float>( quantity * 2, havenull,
                                               nullstring, out );
            }
            break;
            case DOUBLECOMPLEX: {
                return readFloatValues<double>( quantity * 2, havenull,
                                                nullstring, out );
            }
            break;
        }

        //  Cannot happen (unless a datatype is missed).
        return false;
    }

    /**
     *  Read a vector of VOTable booleans from the stream and write the
     *  decoded values to the output stream. Result is false if the read
     *  fails. If a null value is encountered then a blank is written.
     */
    bool VOTableStream::readBooleans( int quantity, ostream *out )
    {
        bool result = true;
        bool value;
        int status;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( readValue( quantity ) ) {
                if ( quantity == 0 ) {
                    //  No value.
                    *out << " ";
                }
            }
            else {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            status = readBoolean( value );
            if ( status == 1 ) {
                *out << boolalpha << value;
            }
            else if ( status == -1 ) {
                *out << " ";
            }
            else {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a VOTable boolean from the stream and return the value.
     *  Result is 0 if the read fails, 1 if it succeeds and -1 if
     *  a null value is encountered.
     */
    int VOTableStream::readBoolean( bool &value )
    {
        char b = in_->sbumpc();
        if ( b != EOF ) {
            if ( b == '\0' || b == '?' || b == ' ' ) {
                return -1;
            }
            else if ( b == 'T' || b == 't' || b == '1' ) {
                value = true;
            }
            else {
                value = false;
            }
            return 1;
        }
        return 0;
    }

    /**
     *  Read a VOTable bit array vector from the stream and write the decoded
     *  values to the output stream. These are single ASCII char whose binary
     *  representation is required. The result is false if the read fails.
     */
    bool VOTableStream::readBitArrays( int quantity, ostream *out )
    {
        bool result = true;
        string value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( readValue( quantity ) ) {
                if ( quantity == 0 ) {
                    //  No value.
                    *out << " ";
                }
            }
            else {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( readBitArray( value ) ) {
                *out << value;
            }
            else {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a VOTable bit array byte from the stream and return the decoded
     *  string representation of the bits. The result is false if the read
     *  fails.
     */
    bool VOTableStream::readBitArray( string &value )
    {
        char b = in_->sbumpc();
        if ( b != EOF ) {
            bitset<8> bs( b );
#if HAVE_BROKEN_BIT_SET
            value = bs.to_string();
#else
            value = bs.to_string< char,char_traits<char>,allocator<char> >();
#endif
            return true;
        }
        return false;
    }

    /**
     *  Read a VOTable byte vector from the stream and write the decoded
     *  values to the output stream. Returns false if the read fails.
     */
    bool VOTableStream::readBytes( int quantity, bool havenull,
                                   string &nullstring, ostream *out )
    {
        bool result = true;
        unsigned char value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( readValue( quantity ) ) {
                if ( quantity == 0 ) {
                    //  No value.
                    *out << " ";
                }
            }
            else {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        //  Extract the null value.
        unsigned char nullvalue;
        if ( havenull ) {
            havenull = from_string( nullstring, nullvalue );
        }

        if ( havenull ) {
            for ( int i = 0; i < quantity; i++ ) {
                if ( readByte( value ) ) {
                    if ( value != nullvalue ) {
                        *out << (unsigned short) value;
                    }
                    *out << " ";
                }
                else {
                    result = false;
                    break;
                }
            }
        }
        else {
            for ( int i = 0; i < quantity; i++ ) {
                if ( readByte( value ) ) {
                    *out << (unsigned short) value << " ";
                }
                else {
                    result = false;
                    break;
                }
            }
        }
        return result;
    }

    /**
     *  Read a VOTable byte from the stream. Returns false if the read fails.
     */
    bool VOTableStream::readByte( unsigned char &value )
    {
        char b = in_->sbumpc();
        if ( b != EOF ) {
            value = (unsigned char) b;
            return true;
        }
        return false;
    }

    /**
     *  Read a VOTable string from the stream and write the formatted
     *  value to the output stream. Usually a string, which can be terminated
     *  by a '\0', not just the quantity. If this is required then the
     *  quantity may be specified as 0.
     */
    bool VOTableStream::readChars( int quantity, ostream *out )
    {
        bool result = true;
        char value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( readValue( quantity ) ) {
                if ( quantity == 0 ) {
                    //  No value.
                    *out << " ";
                }
            }
            else {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( readChar( value ) ) {
                if ( value == '\0' ) {
                    //  End of string, so don't print more, but we 
                    //  need to read stream for required quantity.
                    continue;
                }
                else {
                    *out << value;
                }
            }
            else {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a VOTable char from the stream and return the decoded value.
     *  Returns false if the read fails.
     */
    bool VOTableStream::readChar( char &value )
    {
        char b = in_->sbumpc();
        if ( b != EOF ) {
            value = b;
            return true;
        }
        return false;
    }

    /**
     *  Read a VOTable unicode string from the stream and write the decoded
     *  value to the output stream. Usually a string, which can be terminated
     *  by a ='\0'. If this is required then the quantity may be specified as
     *  0. Returns false if the read fails. Note the output stream does not
     *  support unicode, so we convert to ASCII and hope for the best.
     */
    bool VOTableStream::readUniChars( int quantity, ostream *out )
    {
        bool result = true;
        char value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( readValue( quantity ) ) {
                if ( quantity == 0 ) {
                    //  No value.
                    *out << " ";
                }
            }
            else {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( readUniChar( value ) ) {
                if ( value == '\0' ) {
                    //  End of string, so don't print more, but we 
                    //  need to read stream for required quantity.
                    continue;
                }
                else {
                    //  Avoid newlines, tabs etc. These will break the format.
                    if ( iscntrl( value ) ) {
                        *out << " ";
                    }
                    else {
                        *out << value;
                    }
                }
            }
            else {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a VOTable unicode character from the stream and return the result
     *  as an ASCII char.  Returns false if the read fails. Note no bigendian
     *  checks as that is assumed by the encoding (UCS-2), so we just return
     *  byte 2 as the ASCII.
     */
    bool VOTableStream::readUniChar( char &value )
    {
        bool result = true;
        char b[2];

        b[0] = in_->sbumpc();
        b[1] = in_->sbumpc();

        if ( ( b[1] == EOF || b[0] == EOF ) ) {
            value = '\0';
            result = false;
        }
        else {
            value = b[1];
        }
        return result;
    }

    /**
     *  Read a vector of floating point values from the input stream and write
     *  them to the output stream. Two types of check for null values is
     *  made, NaNs are checked and also a nullvalue, if given. Both are
     *  replaced by a blank.
     *
     *  If the read fails them false is returned.
     */
    template <typename T>
    bool VOTableStream::readFloatValues( int quantity, bool havenull,
                                         string &nullstring, ostream *out )
    {
        bool result = true;
        T value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( readValue( quantity ) ) {
                if ( quantity == 0 ) {
                    //  No value.
                    *out << " ";
                }
            }
            else {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        T nullvalue;
        if ( havenull ) {
            havenull = from_string( nullstring, nullvalue );
        }

        if ( havenull ) {
            for ( int i = 0; i < quantity; i++ ) {
                if ( readValue( value ) ) {
                    if ( ! isnan( value ) && value != nullvalue ) {
                        *out << value;
                    }
                    *out << " ";
                }
                else {
                    result = false;
                    break;
                }
            }
        }
        else {
            for ( int i = 0; i < quantity; i++ ) {
                if ( readValue( value ) ) {
                    if ( ! isnan( value ) ) {
                        *out << value <<  " ";
                    }
                    *out << " ";
                }
                else {
                    result = false;
                    break;
                }
            }
        }
        return result;
    }

    /**
     *  Read a vector of values from the input stream and write
     *  them to the output stream. If given any null values will be
     *  replaced by a blank.
     *
     *  If the read fails them false is returned.
     */
    template <typename T>
    bool VOTableStream::readValues( int quantity, bool havenull,
                                    string &nullstring, ostream *out )
    {
        bool result = true;
        T value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( readValue( quantity ) ) {
                if ( quantity == 0 ) {
                    //  No value.
                    *out << " ";
                }
            }
            else {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        T nullvalue;
        if ( havenull ) {
            havenull = from_string( nullstring, nullvalue );
        }

        if ( havenull ) {
            for ( int i = 0; i < quantity; i++ ) {
                if ( readValue( value ) ) {
                    if ( value != nullvalue ) {
                        *out << value;
                    }
                    *out << " ";
                }
                else {
                    result = false;
                    break;
                }
            }
        }
        else {
            for ( int i = 0; i < quantity; i++ ) {
                if ( readValue( value ) ) {
                    *out << value <<  " ";
                }
                else {
                    result = false;
                    break;
                }
            }
        }
        return result;
    }

    /**
     *  Read a value from the input stream and return it. The data type
     *  defines how the function works (should only be used for the numeric
     *  data types, short, int, float and double). If the read fails them
     *  false is returned.
     */
    template <typename T>
    bool VOTableStream::readValue( T &value )
    {
        union {
            char b[sizeof(T)];
            T value;
        } u;

        //  We do not check each read for success as a byte can have any
        //  pattern when it represents part of another value. So see if at
        //  least sizeof(T) bytes are available.
        if ( in_->in_avail() >= (int) sizeof(T) ) {
            if ( bigendian_ ) {
                for ( int j = 0; j < (int) sizeof(T); j++ ) {
                    u.b[j] = in_->sbumpc();
                }
            }
            else {
                for ( int j = sizeof(T) - 1; j >= 0; j-- ) {
                    u.b[j] = in_->sbumpc();
                }
            }
            value = u.value;
            return true;
        }
        return false;
    }


    //  BINARY2 specific support.

    /**
     *  Read n bytes from the stream and interpret as a BINARY2 null bit mask.
     *  Returning the 0/1 bit values as false/true in the bitmask array.
     *  The bitmask array should be of size n*8.
     */
    bool VOTableStream::readBitMask( int n, bool bitmask[] )
    {
        bool result = true;
        char b;
        int k = 0;

        for ( int i = 0; i < n; i++ ) {
            char b = in_->sbumpc();
            if ( b != EOF ) {
                bitset<8> bs( b );
                for ( int j = 7; j >= 0; j-- ) {
                    bitmask[k] = bs.test( j );
                    k++;
                }
            }
            else {
                result = false;
                break;
            }
        }

        return result;
    }

    /**
     *  Read a supported vector of data objects from the input stream and
     *  discard their content. Returns false if the read fails. Use to skip
     *  over null elements in a BINARY2 stream.
     */
    bool VOTableStream::readSkip( datatype type, int quantity )
    {
        switch ( type ) {
            case BOOLEAN: {
                return skipBooleans( quantity );
            }
            break;
            case BITARRAY: {
                return skipBitArrays( quantity );
            }
            break;
            case BYTE: {
                return skipBytes( quantity );
            }
            break;
            case CHAR: {
                return skipChars( quantity );
            }
            break;
            case UNICODE: {
                return skipUniChars( quantity );
            }
            break;
            case SHORT: {
                return skipValues<short>( quantity );
            }
            break;
            case INT: {
                return skipValues<int>( quantity );
            }
            break;
            case LONG: {
                if ( uselonglong_ ) {
                    return skipValues<long long>( quantity );
                }
                else {
                    return skipValues<long>( quantity );
                }
            }
            break;
            case FLOAT: {
                return skipValues<float>( quantity );
            }
            break;
            case DOUBLE: {
                return skipValues<double>( quantity );
            }
            break;
            case FLOATCOMPLEX: {
                return skipValues<float>( quantity * 2 );
            }
            break;
            case DOUBLECOMPLEX: {
                return skipValues<double>( quantity * 2 );
            }
            break;
        }

        //  Cannot happen (unless a datatype is missed).
        return false;
    }

    /**
     *  Read a vector of VOTable booleans from the stream and discard
     *  them. Result is false if the read fails.
     */
    bool VOTableStream::skipBooleans( int quantity )
    {
        bool result = true;
        bool value;
        int status;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( ! readValue( quantity ) ) {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( ! readBoolean( value ) ) {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a VOTable bit array vector from the stream and discard.
     *  The result is false if the read fails.
     */
    bool VOTableStream::skipBitArrays( int quantity )
    {
        bool result = true;
        string value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( ! readValue( quantity ) ) {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( ! readBitArray( value ) ) {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a VOTable byte vector from the stream and discard.
     *  Returns false if the read fails.
     */
    bool VOTableStream::skipBytes( int quantity )
    {
        bool result = true;
        unsigned char value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( ! readValue( quantity ) ) {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( ! readByte( value ) ) {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a VOTable string from the stream and discard. 
     */
    bool VOTableStream::skipChars( int quantity )
    {
        bool result = true;
        char value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( ! readValue( quantity ) ) {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( readChar( value ) ) {
                if ( value == '\0' ) {
                    //  End of string, so don't print more, but we 
                    //  need to read stream for required quantity.
                    continue;
                }
            }
            else {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a VOTable unicode string from the stream and discard.
     */
    bool VOTableStream::skipUniChars( int quantity )
    {
        bool result = true;
        char value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( ! readValue( quantity ) ) {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( ! readUniChar( value ) ) {
                result = false;
                break;
            }
        }
        return result;
    }

    /**
     *  Read a vector of values from the input stream and discard.
     *  If the read fails then false is returned.
     */
    template <typename T>
        bool VOTableStream::skipValues( int quantity )
    {
        bool result = true;
        T value;

        //  If runlength encoded, first four bytes are the quantity.
        if ( quantity == 0 ) {
            if ( ! readValue( quantity ) ) {
                /*  End of stream. */
                result = false;
                quantity = 0;
            }
        }

        for ( int i = 0; i < quantity; i++ ) {
            if ( ! readValue( value ) ) {
                result = false;
                break;
            }
        }
        return result;
    }
}
