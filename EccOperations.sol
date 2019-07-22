pragma solidity ^0.5.0;

contract EccOperations {
	// Curve parameters of brainpoolP256r1.
	uint256 constant p = 0xA9FB57DBA1EEA9BC3E660A909D838D726E3BF623D52620282013481D1F6E5377;
	uint256 constant n = 0xA9FB57DBA1EEA9BC3E660A909D838D718C397AA3B561A6F7901E0E82974856A7;
	uint256 constant a = 0x7D5A0975FC2C3057EEF67530417AFFE7FB8055C126DC5C6CE94A4B44F330B5D9;
	uint256 constant b = 0x26DC5C6CE94A4B44F330B5D9BBD77CBF958416295CF7E1CE6BCCDC18FF8C07B6;

	function inverseModP(uint256 num) public pure returns(uint256 inverseNumber) {
		uint256 t = 0;
		uint256 newT = 1;
		uint256 r = p;
		uint256 newR = num;
		uint256 q;
		while (newR != 0) {
			q = r / newR;

			(t, newT) = (newT, addmod(t, (p - mulmod(q, newT, p)), p));
			(r, newR) = (newR, r - q * newR );
		}

		return t;
	}

	function inverseModN(uint256 num) public pure returns(uint256 inverseNumber) {
		uint256 t = 0;
		uint256 newT = 1;
		uint256 r = n;
		uint256 newR = num;
		uint256 q;
		while (newR != 0) {
			q = r / newR;

			(t, newT) = (newT, addmod(t, (n - mulmod(q, newT, n)), n));
			(r, newR) = (newR, r - q * newR );
		}

		return t;
	}

	function getNeutral() public pure returns(uint256 x, uint256 y) {
		return (0,0);
	}

	function add(uint256 x_p, uint256 y_p, uint256 x_q, uint256 y_q) public pure returns(uint256 x2, uint256 y2) {
		(uint256 x_z, uint256 y_z) = getNeutral();
		if(x_p == x_z && y_p == y_z) {
			return (x_q, y_q);
		}
		if(x_q == x_z && y_q == y_z) {
			return (x_p, y_p);
		}

		uint256 o;
		if(y_p >= y_q) {
			o = y_p - y_q;
		} else {
			o = y_p + p - y_q;
		}

		uint256 u;
		if(x_p >= x_q) {
			u = x_p - x_q;
		} else {
			u = x_p + p - x_q;
		}

		uint256 s = mulmod(o, inverseModP(u), p);

		uint256 x = mulmod(s, s, p);
		if(x >= x_p) {
			x -= x_p;
		} else {
			x = x + p - x_p;
		}
		if(x >= x_q) {
			x -= x_q;
		} else {
			x = x + p - x_q;
		}

		uint256 i;
		if(x_p >= x) {
			i = x_p - x;
		} else {
			i = x_p + p - x;
		}

		uint256 y = mulmod(s, i, p);
		if(y >= y_p) {
			y -= y_p;
		} else {
			y = y + p - y_p;
		}

		return (x, y);
	}

	function double(uint256 x0, uint256 y0) public pure returns(uint256 x1Res, uint256 y1Res) {
		if(y0 == 0) {
			return getNeutral();
		}
		
		uint256 twoYInv = inverseModP(mulmod(2, y0, p));
		uint256 s = mulmod(addmod(mulmod(3, mulmod(x0, x0, p), p), a, p), twoYInv, p);
		uint256 x1L = mulmod(s, s, p);
		uint256 x1R = mulmod(2, x0, p);
		uint256 x1;
		if(x1L > x1R) {
			x1 = x1L - x1R;
		} else {
			x1 = x1L + p - x1R;
		}
		uint256 x0minusx1;
		if(x0 > x1) {
			x0minusx1 = x0 - x1;
		} else {
			x0minusx1 = x0 + p - x1;
		}
		uint256 y1L = y0;
		uint256 y1R = mulmod(s, x0minusx1, p);
		uint256 y1;
		if(y1L < y1R) {
			y1 = y1R - y1L;
		} else {
			y1 = y1R + p- y1L;
		}

		return (x1, y1);
	}

	function multiplyScalar(uint256 x0, uint256 y0, uint scalar) public pure returns(uint256 x1, uint256 y1) {
		uint256 P_x = x0;
		uint256 P_y = y0;
		(uint256 Q_x, uint256 Q_y) = getNeutral();

		for(uint256 i=255; true; i--) {
			(Q_x, Q_y) = double(Q_x, Q_y);
			
			if((scalar & (1 << i)) > 0) {
				(Q_x, Q_y) = add(P_x, P_y, Q_x, Q_y);
			}

			if(i == 0) {
				break;
			}
		}

		return (Q_x, Q_y);
	}
}
