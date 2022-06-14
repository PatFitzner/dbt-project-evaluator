-- this model finds cases where a model has a reference to both a model and a source

with direct_model_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where child_resource_type = 'model'
    and distance = 1
),

model_and_source_joined as (
    select
        child
    from direct_model_relationships
    group by 1
    having 
        sum(case when parent_resource_type = 'model' then 1 else 0 end) > 0 
        and sum(case when parent_resource_type = 'source' then 1 else 0 end) > 0
),

final as (
    select 
        direct_model_relationships.*
    from direct_model_relationships
    inner join model_and_source_joined
    on direct_model_relationships.child = model_and_source_joined.child
    order by direct_model_relationships.child
)

select * from final




{% set query_filters %}
select 
    column_name, 
    id_to_exclude 
from {{ ref('dbt_project_evaluator_exceptions') }}
where fct_name = '{{ this.name }}'
{% endset %}

{% if execute %}
where 1 = 1
{% for row_filter in run_query(query_filters) %}
    and {{ row_filter["column_name"] }} <> '{{ row_filter["id_to_exclude"] }}'
{% endfor %}

{% endif %}