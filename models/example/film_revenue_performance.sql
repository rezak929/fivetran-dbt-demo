WITH film_inventory AS (
    SELECT
        i.INVENTORY_ID,
        i.STORE_ID,
        f.FILM_ID,
        f.TITLE,
        f.RATING,
        f.RENTAL_RATE,
        f.REPLACEMENT_COST,
        f.LENGTH,
        f.RENTAL_DURATION
    FROM DEMO.POSTGRES_RDS_PUBLIC.INVENTORY i
    JOIN DEMO.POSTGRES_RDS_PUBLIC.FILM f
        ON i.FILM_ID = f.FILM_ID
    WHERE i._FIVETRAN_DELETED = FALSE
      AND f._FIVETRAN_DELETED = FALSE
),

rental_payments AS (
    SELECT
        r.RENTAL_ID,
        r.INVENTORY_ID,
        r.CUSTOMER_ID,
        r.RENTAL_DATE,
        r.RETURN_DATE,
        DATEDIFF('day', r.RENTAL_DATE, r.RETURN_DATE) AS days_rented,
        COALESCE(p.AMOUNT, 0) AS payment_amount
    FROM DEMO.POSTGRES_RDS_PUBLIC.RENTAL r
    LEFT JOIN DEMO.POSTGRES_RDS_PUBLIC.PAYMENT p
        ON r.RENTAL_ID = p.RENTAL_ID
    WHERE r._FIVETRAN_DELETED = FALSE
),

film_performance AS (
    SELECT
        fi.FILM_ID,
        fi.TITLE,
        fi.RATING,
        fi.RENTAL_RATE,
        fi.REPLACEMENT_COST,
        fi.LENGTH,
        fi.RENTAL_DURATION,
        fi.STORE_ID,
        COUNT(rp.RENTAL_ID)                         AS total_rentals,
        SUM(rp.payment_amount)                      AS total_revenue,
        AVG(rp.payment_amount)                      AS avg_payment,
        AVG(rp.days_rented)                         AS avg_days_rented,
        SUM(CASE WHEN rp.RETURN_DATE IS NULL
            THEN 1 ELSE 0 END)                      AS currently_rented
    FROM film_inventory fi
    LEFT JOIN rental_payments rp
        ON fi.INVENTORY_ID = rp.INVENTORY_ID
    GROUP BY 1,2,3,4,5,6,7,8
)

SELECT
    FILM_ID,
    TITLE,
    RATING,
    RENTAL_RATE,
    REPLACEMENT_COST,
    LENGTH,
    RENTAL_DURATION,
    STORE_ID,
    total_rentals,
    total_revenue,
    avg_payment,
    ROUND(avg_days_rented, 1)                       AS avg_days_rented,
    currently_rented,
    ROUND(total_revenue / NULLIF(REPLACEMENT_COST, 0) * 100, 1) AS roi_pct
FROM film_performance
WHERE total_rentals > 0
ORDER BY total_revenue DESC
