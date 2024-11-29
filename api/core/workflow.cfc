<cfcomponent displayname="coreWorkflow" output="false">

	<cffunction access="public" name="getWorkflowStatusCountForDashboard" returntype="struct">
		<cfargument name="lib_id" type="numeric" required>
		<cfargument name="user_id" type="string" required="false" default="">


		<cfquery name="qWorkflowCountsByUserRoles" datasource="#REQUEST.dsns.onei00maindb#">
			WITH workflows_by_user_roles AS (
				SELECT TD.ItemSeqNo,
					MAX(CASE WHEN ToDoOrActiveOrCompleted = 'ToDo' THEN 1 ELSE 0 END) AS HasToDo,
					MAX(CASE WHEN ToDoOrActiveOrCompleted = 'Active' THEN 1 ELSE 0 END) AS HasActive,
					MAX(CASE WHEN ToDoOrActiveOrCompleted = 'Completed' THEN 1 ELSE 0 END) AS HasCompleted
				FROM	[1i00_Central]..WFS_Item_ToDo TD
					INNER JOIN [1i00_Central]..WFS_Item_ToDo_Roles TDR ON TDR.ItemSeqNo = TD.ItemSeqNo
					AND TDR.LibraryID = TD.LibraryID
				WHERE	TD.LibraryID = <cfqueryparam value="#lib_id#" cfsqltype="CF_SQL_INTEGER">
				<cfif user_id neq "">
					AND		TDR.UserID = <cfqueryparam value="#user_id#" cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				GROUP BY TD.ItemSeqNo
			),

 		  workflows_with_status AS (
				SELECT ITM.ItemSeqNo, 
				CASE
					WHEN (ITM.Item_Status = 1 OR ITM.Item_Status = -1)
						AND	ITM.Item_OnHold <> 1
						-- AND NOT (TSK.WFS_CorrectedProofToDo = 1
						-- 	OR TSK.WFS_CopyFilesToDAMBinsPostFinish = 'ToDo')
					THEN 1
					ELSE 0
				END AS isPending,
				CASE
					WHEN ( 1=0
						OR ITM.Item_Status = 1 
						OR ITM.Item_Status = -1
						OR TSK.WFS_CorrectedProofToDo = 1
						OR TSK.WFS_CopyFilesToDAMBinsPostFinish = 'ToDo'
						) AND HasTodo = 1
					THEN 1
					ELSE 0
				END AS isPendingToDo,
				CASE
					WHEN (ITM.Item_Status = 1 OR ITM.Item_Status = -1)
						AND		ITM.Item_OnHold = 1
					THEN 1
					ELSE 0
				END AS isPendingOnHold

				FROM workflows_by_user_roles AS WF
					INNER JOIN [1i00_Central]..i00wf_Item ITM
						ON ITM.ItemSeqNo = WF.ItemSeqNo
							AND ITM.LibraryID = <cfqueryparam value="#lib_id#" cfsqltype="CF_SQL_INTEGER">
							AND	ITM.Item_WFS = 1
							AND	ITM.Item_is_deleted = 0
					INNER JOIN [1i00_Central]..WFS_Task TSK
						ON WF.ItemSeqNo = TSK.ItemSeqNo
							AND TSK.LibraryID = <cfqueryparam value="#lib_id#" cfsqltype="CF_SQL_INTEGER">
			)

			SELECT 
				totals.PendingCount, 
				totals.ToDoCount, 
				totals.OnHoldCount, 
				totals.TotalCount,
				ROUND((totals.PendingCount / totals.TotalCount) * 100, 2) as PendingPercent,
				ROUND((totals.ToDoCount / totals.TotalCount) * 100, 2) as ToDoPercent,
				ROUND((totals.OnHoldCount / totals.TotalCount) * 100, 2) as OnHoldPercent
			FROM
			(
				SELECT 
					SUM(isPending) as PendingCount,
					SUM(isPendingToDo) as ToDoCount,
					SUM(isPendingOnHold) as OnHoldCount,
					CAST(SUM(isPendingToDo) + SUM(isPendingOnHold)  + SUM(isPending) AS FLOAT) as TotalCount
				FROM workflows_with_status
			) as totals
		</cfquery>

		<cfreturn qWorkflowCountsByUserRoles.getRow(1)>
	</cffunction>

	<cffunction access="public" name="getWorkflowStatusCount" returntype="struct">
		<cfargument name="lib_id" type="numeric" required>
		<cfargument name="user_id" type="string" required="false" default="">
		
		<cfset filter_by_user_id = isDefined("arguments.user_id") && arguments.user_id !== "">

		<cfquery name="q_workflows_status_count" datasource="#request.dsns.onei00maindb#">
			DECLARE @LibID INT = <cfqueryparam value="#arguments.lib_id#" cfsqltype="CF_SQL_INTEGER">
			<cfif filter_by_user_id>
			DECLARE @UserID NVARCHAR(100) = <cfqueryparam value="#arguments.user_id#" cfsqltype="CF_SQL_VARCHAR">
			</cfif>
			SELECT 
				SUM(is_pending) as pending_count
				/*,SUM(is_todo) as todo_count*/
				,SUM(is_onhold) as onhold_count
				,SUM(is_unreleased) as unreleased_count
				,SUM(is_completed) as completed_count
				,SUM(is_deleted) as deleted_count
				,SUM(is_overdue) as overdue_count
			FROM (
				SELECT TOP 40000

					/*pending*/
					CASE WHEN Item_Status = 1 OR Item_Status = -1 THEN 1 ELSE 0 END AS is_pending
			
					/*todo seems to just be my_pending vs all_pending*/
					/*
					,CASE WHEN (Item_Status = 1 OR Item_Status = -1) AND FilteredByUser IS NOT NULL
					--OR WFS_CorrectedProofToDo = 1 OR WFS_CopyFilesToDAMBinsPostFinish = 'ToDo' 
					THEN 1 ELSE 0 END AS is_todo */
			
					/*onhold*/
					,CASE WHEN Item_OnHold = 1 THEN 1 ELSE 0 END AS is_onhold
					
					/*unreleased*/
					,CASE WHEN Item_Status = 0 THEN 1 ELSE 0 END AS is_unreleased
					
					/*completed*/
					,CASE WHEN Item_Status >= 2 OR Item_Status = -2 THEN 1 ELSE 0 END AS is_completed
					
					/*deleted*/
					,CASE WHEN Item_is_deleted = 1 AND Item_is_archived = 0 THEN 1 ELSE 0 END AS is_deleted
					
					/*overdue*/
					,CASE WHEN wf.Item_wf_DueDate < GETDATE() THEN 1 ELSE 0 END AS is_overdue
			
				FROM dbo.i00wf_Item AS wf
				
				<cfif filter_by_user_id>
				CROSS APPLY (
					SELECT TOP 1 UserID AS FilteredByUser
					FROM ( 
						SELECT ISNULL(FixedMapping_Usergroup_SelectedUserID, FixedMapping_UserID) AS UserID 
						FROM [dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
						WHERE wf_r2u_map.LibraryID = wf.LibraryID
						AND	wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					) wf_users
					WHERE UserID = @UserID
				) has_user_in_role_filter
				</cfif>
				
				WHERE LibraryID = @LibID
			) status_flags
		</cfquery>

		<cfreturn q_workflows_status_count.getRow(1)>
	</cffunction>

	<cffunction access="public" name="getWorkflowList" returntype="array">
		<cfargument name="library_id" type="numeric">
		<cfargument name="user_id" type="string">
		<cfargument name="jwtData" type="struct">

		<cfscript>
			filter_by_user_id = isDefined("arguments.user_id") && arguments.user_id !== "";
			filter_by_library_id = isDefined("arguments.library_id") && isNumeric(arguments.library_id);
		</cfscript>

		<!--- <cfquery name="arr_workflows" returntype="array" datasource="#request.dsns.onei00maindb#"> --->
		<cfquery name="arr_workflows" returntype="array" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">
			<cfif filter_by_user_id>
			DECLARE @UserID NVARCHAR(100) = <cfqueryparam value="#arguments.user_id#" cfsqltype="CF_SQL_VARCHAR">,
			@libraryid NVARCHAR(100) = <cfqueryparam value="#arguments.library_id#" cfsqltype="CF_SQL_VARCHAR">
			</cfif>

			SELECT TOP 4000
				wf.LibraryID
				,wf.ItemSeqNo
				,workflow_fields.*
				--,wf.*
				,UserList 
				,UserGroupList
				,StageCodeList 
				,open_stage.* 
				,open_stage_roles.*
				,open_stage_user_list.*
				,open_stage_Aprover.*
				,open_stage_user_group_list.*
				,stage_progress.*
				,open_stage_progress.*
				,CAST((CAST(finished_roles AS float)/CAST(total_roles AS float)) * 100 AS INT) AS current_stage_progress
				,CAST(((CAST(finished_stages AS float)+(CAST(finished_roles AS float)/CAST(total_roles AS float)))/CAST(total_stages AS float)) * 100 AS INT) AS total_progress
				,wf.Item_StandardClassifier_WorkflowSubType
	
			FROM [1i00_Central].dbo.[i00wf_Item] AS wf

			<cfif filter_by_user_id>
			CROSS APPLY (
				SELECT TOP 1 UserID AS FilteredByUser
				FROM ( 
					SELECT ISNULL(FixedMapping_Usergroup_SelectedUserID, FixedMapping_UserID) AS UserID 
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND	wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
				) wf_users
				WHERE UserID = @UserID
				AND wf.libraryid = @libraryid
			) has_user_in_role_filter
			</cfif>

			OUTER APPLY (
				SELECT STRING_AGG(UserID, ',') AS UserList, COUNT(UserID) AS UserCount FROM (  
					SELECT DISTINCT ISNULL(FixedMapping_Usergroup_SelectedUserID, CASE WHEN FixedMapping_UsergroupID IS NULL THEN FixedMapping_UserID ELSE NULL END) AS UserID 
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND	wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
				) wf_users
				WHERE UserID IS NOT NULL AND UserID <> ''
			) wf_user_list

			OUTER APPLY (
				SELECT STRING_AGG(UserGroupID, ',') AS UserGroupList, COUNT(UserGroupID) AS UserGroupCount FROM (
					SELECT DISTINCT FixedMapping_UsergroupID AS UserGroupID
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND	wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					AND FixedMapping_UsergroupID IS NOT NULL
					AND FixedMapping_UsergroupID <> ''
				) wf_usergroups
			) wf_usergroup_list

			CROSS APPLY (
				SELECT StageCode AS Open_StageCode, 
				Stage_current_iteration AS Open_Iteration,
				(
					SELECT  Stage_Description 
					FROM [1i00_Central].[dbo].[WFS_WorkFlowType_Stages] stages
					WHERE stages.StageCode = stage_track.StageCode
					AND stages.WorkFlowTypeCode = stage_track.WorkFlowTypeCode
				) AS Open_StageDesc
				FROM [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
				WHERE stage_track.LibraryID = wf.LibraryID
				AND stage_track.ItemSeqNo = wf.ItemSeqNo
				AND stage_track.Stage_started = 1
				AND stage_track.Stage_finished = 0
				AND stage_track.Stage_was_skipped = 0
			) open_stage

			CROSS APPLY (
				SELECT STRING_AGG(RoleCode, ',') AS Open_RoleCodeList FROM [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
				WHERE stage_roles.LibraryID = wf.LibraryID
					AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
					AND stage_roles.StageCode = open_stage.Open_StageCode
					AND stage_roles.StageIterationNo = open_stage.Open_Iteration
					AND RST_IsOpen = 1 
					AND RST_IsSkipping = 0
				HAVING COUNT(RoleCode) > 0
			) open_stage_roles

			CROSS APPLY (
				SELECT STRING_AGG(wf_users.UserID, ',') AS Open_RoleUserList
				,STRING_AGG(sg_users.first_name, ',') AS Open_RoleUserListNames
				,STRING_AGG(LEFT(sg_users.first_name, 1), ',') AS Open_RoleUserListInitials
				FROM (  
					SELECT DISTINCT ISNULL(FixedMapping_Usergroup_SelectedUserID, CASE WHEN FixedMapping_UsergroupID IS NULL THEN FixedMapping_UserID ELSE NULL END) AS UserID 
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					INNER JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
						ON stage_roles.LibraryID = wf.LibraryID 
						AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
						AND stage_roles.StageCode = open_stage.Open_StageCode
						AND stage_roles.StageIterationNo = open_stage.Open_Iteration
						AND RST_IsOpen = 1 
						AND RST_IsSkipping = 0
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					AND wf_r2u_map.RoleCode = stage_roles.RoleCode
				) wf_users
				INNER JOIN [1i00_SmarterWare]..sg_users sg_users ON sg_users.userid = 	wf_users.UserID
				WHERE wf_users.UserID IS NOT NULL AND wf_users.UserID <> ''
			) open_stage_user_list

			CROSS APPLY (
				Select ISNULL((
					Select ISNULL(sg_users.first_name + ' ' + sg_users.last_name, ' - ') as ApprName,'Manager' AS Role,
						LEFT(sg_users.first_name, 1) AS Initial
					FROM 
					(
						SELECT DISTINCT ISNULL(FixedMapping_Usergroup_SelectedUserID, CASE WHEN FixedMapping_UsergroupID IS NULL THEN FixedMapping_UserID ELSE NULL END) UserID			
						FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
						INNER JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles 
						ON stage_roles.LibraryID = wf.LibraryID 
						AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
						AND stage_roles.StageCode = open_stage.Open_StageCode
						AND stage_roles.StageIterationNo = open_stage.Open_Iteration
						AND RST_IsOpen = 1 
						AND RST_IsSkipping = 0
						INNER JOIN  [1i00_Central].[dbo].[WFS_WorkFlowType_Roles] wf_roles 
						ON wf_r2u_map.RoleCode = wf_roles.RoleCode 
						AND wf_r2u_map.WorkFlowTypeCode = wf_roles.WorkFlowTypeCode  
						AND wf_roles.Role_Description = 'Job Manager'
						WHERE wf_r2u_map.LibraryID = wf.LibraryID
						AND wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					) AS wf_ApproverData
					LEFT JOIN [1i00_SmarterWare]..sg_users sg_users ON sg_users.userid = 	wf_ApproverData.UserID
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				) ,'{"ApprName":" - ","Role":"Manager","Initial":" - "}') AS wf_Approver
			) open_stage_Aprover

			CROSS APPLY (
				SELECT STRING_AGG(UserGroupID, ',') AS Open_RoleUserGroupList FROM (
					SELECT DISTINCT FixedMapping_UsergroupID AS UserGroupID
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					INNER JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
						ON stage_roles.LibraryID = wf.LibraryID 
						AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
						AND stage_roles.StageCode = open_stage.Open_StageCode
						AND stage_roles.StageIterationNo = open_stage.Open_Iteration
						AND RST_IsOpen = 1 
						AND RST_IsSkipping = 0
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					AND wf_r2u_map.RoleCode = stage_roles.RoleCode
				) wf_usergroups
				WHERE UsergroupID IS NOT NULL
					AND UsergroupID <> ''
			) open_stage_user_group_list


			CROSS APPLY (
				SELECT STRING_AGG(StageCode,',') AS StageCodeList FROM [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
				WHERE stage_track.LibraryID = wf.LibraryID
				AND stage_track.ItemSeqNo = wf.ItemSeqNo
			) stages

			/*cross apply display fields after filters have applied*/
			CROSS APPLY (
				SELECT 
					Item_Resource_RUID,
					'/cfm/SmartGate/Applications/ColdRTI/getImage.cfm?r=1&ruid='+cast(Item_Resource_RUID as varchar(50))+'&IsAjax=true&bin=1' AS fileImage, 
					Item_wf_StartDate,
					FORMAT(Item_wf_StartDate, 'dd MMM yyyy') AS startDate,
					Item_wf_IntermediateDate,
					FORMAT(Item_wf_IntermediateDate, 'dd MMM yyyy') AS proofTime,
					Item_wf_DueDate,
					FORMAT(Item_wf_DueDate, 'dd MMM yyyy') AS endDate,
					Item_wf_DueTime,
					Item_wf_Objective,
					Item_wf_TextNote,
					ISNULL(NULLIF((Item_StandardClassifier_Barcode),''),' - ') AS Item_StandardClassifier_Barcode,
					ISNULL(NULLIF((Item_StandardClassifier_ProductCode),''),' - ') AS Item_StandardClassifier_ProductCode,
					ISNULL(NULLIF((Item_StandardClassifier_ArtworkNumber),''),' - ') AS Item_StandardClassifier_ArtworkNumber,
					wf_type.*,
					folder.*,
					CONCAT('["', Folder_Division, '", "', Folder_Brand, '", "', Folder_SubBrand, '", "', Folder_Group, '", "', Folder_SubGroup, '"]') AS categories
				FROM [1i00_Central].dbo.[i00wf_Item] AS wf_core

				CROSS APPLY (
					SELECT 
						WFS_WorkFlowTypeCode AS Type_Code,
						wf_type.WorkFlowType_Description AS Type_Desc
					FROM [1i00_Central].[dbo].[WFS_Task] wf_task
					INNER JOIN [1i00_Central].[dbo].[WFS_WorkFlowType] wf_type
					ON wf_task.LibraryID = wf_core.LibraryID
					AND wf_task.ItemSeqNo = wf_core.ItemSeqNo
					AND wf_task.WFS_WorkFlowTypeCode = wf_type.WorkFlowTypeCode
				) wf_type 

				CROSS APPLY (
					SELECT 
						catalogue_no AS Folder_ID
						,description AS Folder_Desc
						,description_long AS Folder_Desc_Long
						,IsWFJobBag AS Folder_IsWFJobBag
						,ISNULL((
							SELECT 
								DivisionName 
							FROM [dbo].[i00L_Divisions] 
							WHERE DivisionCode = folders.i00division
						),' - ') AS Folder_Division
						,ISNULL((
							SELECT 
								BrandDesc 
							FROM [dbo].[i00L_Brands] 
							WHERE BrandID = folders.Brand
						),' - ') AS Folder_Brand
						,ISNULL((
							SELECT
								SubBrandDesc
							FROM [dbo].[i00L_SubBrands]
							WHERE BrandID = folders.Brand
							AND SubBrandID = folders.SubBrand
						),' - ') AS Folder_SubBrand
						,ISNULL((
							SELECT 
								GroupDesc 
							FROM [dbo].[i00L_Groups] 
							WHERE GroupID = folders.PrGroup
						),' - ') AS Folder_Group
						,ISNULL((
							SELECT 
								SubGroupDesc 
							FROM [dbo].[i00L_SubGroups] 
							WHERE GroupID = folders.PrGroup
							AND SubGroupID = folders.SubGroup
						),' - ') AS Folder_SubGroup
					FROM [dbo].[i00L_ProductRecord] folders
					INNER JOIN [dbo].[i00L_ProdRes_m2m] project_m2m
					ON project_m2m.product_catalogue_no = folders.catalogue_no
					WHERE project_m2m.resource_RUID = wf_core.Item_Resource_RUID
				) folder



				WHERE wf_core.LibraryID = wf.LibraryID
					AND wf_core.ItemSeqNo = wf.ItemSeqNo

			
			) workflow_fields

			OUTER APPLY (
				SELECT SUM(
					CASE WHEN Stage_finished = 1 OR Stage_was_skipped = 1 THEN 1 ELSE 0 END
				) AS finished_stages,
				COUNT( StageCode ) AS total_stages
				FROM  [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
				WHERE stage_track.LibraryID = wf.LibraryID
				AND stage_track.ItemSeqNo = wf.ItemSeqNo
			) stage_progress


			OUTER APPLY (
				SELECT SUM(
					CASE WHEN RoleSection_DateOut IS NOT NULL OR RST_IsSkipping = 1 THEN 1 ELSE 0 END
				) AS finished_roles,
				COUNT( RoleCode ) AS total_roles
				
				FROM [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
				WHERE stage_roles.LibraryID = wf.LibraryID
					AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
					AND stage_roles.StageCode = open_stage.Open_StageCode
					AND stage_roles.StageIterationNo = open_stage.Open_Iteration
			) open_stage_progress


			WHERE NOT (Open_RoleUserList IS NULL AND Open_RoleUserGroupList IS NULL)
			AND wf.Item_OnHold = 0
		</cfquery>
		
		<cfreturn arr_workflows>
	</cffunction>

	<cffunction access="public" name="searchWorkflowList" returntype="struct">
		<cfargument name="jwtData" type="struct" required="true">
		<cfargument name="searchArgs" type="struct" required="true">
		<!--- Search Args
			<!--- optional search params --->
			<cfargument name="search_text" type="string" required="false" default="">
			<cfargument name="item_seq_no_list" type="string" required="false" default="">
			<cfargument name="productCode" type="string" required="false" default="">
			<cfargument name="artworkNumber" type="string" required="false" default="">
			<cfargument name="barcode" type="string" required="false" default="">
			<cfargument name="tag_id_list" type="string" required="false" default="">
			<cfargument name="typeCode" type="string" required="false" default="">
			<cfargument name="division" type="string" required="false" default="">
			<cfargument name="brand" type="string" required="false" default="">
			<cfargument name="subbrand" type="string" required="false" default="">
			<cfargument name="group" type="string" required="false" default="">
			<cfargument name="subgroup" type="string" required="false" default="">
			<!--- search flags --->
			<cfargument name="mineOnly" type="boolean" required="false" default="true">
			<cfargument name="showDeleted" type="boolean" required="false" default="false">
			<cfargument name="showOnHold" type="boolean" required="false" default="false">
		--->
		
		<!--- set boolean flags for which query sections to include --->
		<Cfset search_arguments = structCopy(arguments.searchArgs)>
		<cfset  filter_by_keywords = (search_arguments.search_text neq "")>
		
		<cfif search_arguments.search_text neq "">
			<cfset searchText = Trim(search_arguments.search_text)>
			<cfloop from="1" to="#Len(searchText)#" index="searchTextIndex">
				<cfif (Asc(Mid(searchText, searchTextIndex, 1)) gte 1 and Asc(Mid(searchText, searchTextIndex, 1)) lte 47)
						or Asc(Mid(searchText, searchTextIndex, 1)) gte 58>
					<cfset alphanumericType = "alpha">
				<cfelse>
					<cfset alphanumericType = "alphanumeric">
				</cfif>
			</cfloop>

			<!--- BH 15/10/2004 requested by Andrew Sleath --->
			<cfset wild="%">
			<cfset search_arguments.search_text=replace(search_arguments.search_text,".",wild,"ALL")>
			<cfset search_arguments.search_text=replace(search_arguments.search_text,"-",wild,"ALL")>
			<cfset search_arguments.search_text=replace(search_arguments.search_text,"/",wild,"ALL")>
			<cfset search_arguments.search_text=replace(search_arguments.search_text,"\",wild,"ALL")>
			<cfset search_arguments.search_text=replace(search_arguments.search_text,"_",wild,"ALL")>
			<cfset search_arguments.search_text=replace(search_arguments.search_text," ",wild,"ALL")>
			<cfset search_arguments.search_text = Replace(search_arguments.search_text, Chr(34), "", "all")>
			<cfset search_arguments.search_text = Replace(search_arguments.search_text, Chr(39), "", "all")>
			<cfset keywords = search_arguments.search_text>
			<Cfset filter_by_keywords = (keywords neq "")>
		</cfif>

		<cfscript>

			filter_by_user_id = search_arguments.mineOnly;
			filter_by_workflow_seqno_list = (search_arguments.item_seqno_list neq "");
			filter_by_search_text = (search_arguments.search_text neq "");

			standard_classifier_filters = ["productCode","artworkNumber","barcode"].filter(function(key){
				return search_arguments[key] neq "";
			});

			m5_classifier_filters = ["division", "brand", "subbrand", "group", "subgroup"].filter(function(key){
				return search_arguments[key] neq "" and search_arguments[key] neq "ALL";
			});
			filter_by_m5_classifiers = (m5_classifier_filters.len() gt 0);

			filter_by_tags = (listLen(search_arguments.tag_id_list) > 0);
		</cfscript>

		<cftry>
		<cfquery name="arr_workflows" returntype="array" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">
			<cfif filter_by_user_id>
			DECLARE @UserID NVARCHAR(100) = <cfqueryparam value="#arguments.jwtData.sessions.userid#" cfsqltype="CF_SQL_VARCHAR">
			</cfif>

			SELECT TOP 4000
				wf.LibraryID
				,wf.ItemSeqNo
				,workflow_fields.*
				--,wf.*
				,UserList 
				,UserGroupList
				,StageCodeList 
				,open_stage.* 
				,open_stage_roles.*
				,open_stage_user_list.*
				,open_stage_Aprover.*
				,open_stage_user_group_list.*
				,stage_progress.*
				,open_stage_progress.*
				,CAST((CAST(finished_roles AS float)/CAST(total_roles AS float)) * 100 AS INT) AS current_stage_progress
				,CAST(((CAST(finished_stages AS float)+(CAST(finished_roles AS float)/CAST(total_roles AS float)))/CAST(total_stages AS float)) * 100 AS INT) AS total_progress,
				wf.Item_StandardClassifier_WorkflowSubType
		
			FROM [1i00_Central].dbo.[i00wf_Item] AS wf

			<cfif filter_by_user_id>
			CROSS APPLY (
				SELECT TOP 1 UserID AS FilteredByUser
				FROM ( 
					SELECT ISNULL(FixedMapping_Usergroup_SelectedUserID, FixedMapping_UserID) AS UserID 
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND	wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
				) wf_users
				WHERE UserID = @UserID
				AND wf.libraryid = '#arguments.jwtData.sessions.libraryid#'
			) has_user_in_role_filter
			</cfif>

			<cfif filter_by_m5_classifiers>
				CROSS APPLY (
					SELECT TOP 1 1 AS has_m5_class
					FROM [dbo].[i00L_ProductRecord] folder
					INNER JOIN [dbo].[i00L_ProdRes_m2m] project_m2m
					ON project_m2m.product_catalogue_no = folder.catalogue_no
					WHERE project_m2m.resource_RUID = wf.Item_Resource_RUID
					AND 1=1
					<!--- Division/Brand/SubBrand/Group/SubGoup - M5 Classifiers --->
					<!--- "division", "brand", "subbrand", "group", "subgroup" --->
					<cfloop array="#m5_classifier_filters#" index="i" item="m5_class">
						AND <cfswitch expression="#m5_class#">
							<cfcase value="division">folder.i00division</cfcase>
							<cfcase value="brand">folder.Brand</cfcase>
							<cfcase value="subbrand">folder.SubBrand</cfcase>
							<cfcase value="group">folder.PrGroup</cfcase>
							<cfcase value="subgroup">folder.SubGroup</cfcase>
						</cfswitch> = <cfqueryparam value="#search_arguments[m5_class]#" cfsqltype="cf_sql_varchar">
					</cfloop>
				) m5_filter <!--- LL NOTE 2024-07-24 this will be switched to a different table eventually --->
			</cfif>


			OUTER APPLY (
				SELECT STRING_AGG(UserID, ',') AS UserList, COUNT(UserID) AS UserCount FROM (  
					SELECT DISTINCT ISNULL(FixedMapping_Usergroup_SelectedUserID, CASE WHEN FixedMapping_UsergroupID IS NULL THEN FixedMapping_UserID ELSE NULL END) AS UserID 
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND	wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
				) wf_users
				WHERE UserID IS NOT NULL AND UserID <> ''
			) wf_user_list

			OUTER APPLY (
				SELECT STRING_AGG(UserGroupID, ',') AS UserGroupList, COUNT(UserGroupID) AS UserGroupCount FROM (
					SELECT DISTINCT FixedMapping_UsergroupID AS UserGroupID
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND	wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					AND FixedMapping_UsergroupID IS NOT NULL
					AND FixedMapping_UsergroupID <> ''
				) wf_usergroups
			) wf_usergroup_list

			CROSS APPLY (
				SELECT StageCode AS Open_StageCode, 
				Stage_current_iteration AS Open_Iteration,
				(
					SELECT  Stage_Description 
					FROM [1i00_Central].[dbo].[WFS_WorkFlowType_Stages] stages
					WHERE stages.StageCode = stage_track.StageCode
					AND stages.WorkFlowTypeCode = stage_track.WorkFlowTypeCode
				) AS Open_StageDesc
				FROM [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
				WHERE stage_track.LibraryID = wf.LibraryID
				AND stage_track.ItemSeqNo = wf.ItemSeqNo
				AND stage_track.Stage_started = 1
				AND stage_track.Stage_finished = 0
				AND stage_track.Stage_was_skipped = 0
			) open_stage

			CROSS APPLY (
				SELECT STRING_AGG(RoleCode, ',') AS Open_RoleCodeList FROM [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
				WHERE stage_roles.LibraryID = wf.LibraryID
					AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
					AND stage_roles.StageCode = open_stage.Open_StageCode
					AND stage_roles.StageIterationNo = open_stage.Open_Iteration
					AND RST_IsOpen = 1 
					AND RST_IsSkipping = 0
				HAVING COUNT(RoleCode) > 0
			) open_stage_roles

			CROSS APPLY (
				SELECT STRING_AGG(wf_users.UserID, ',') AS Open_RoleUserList
				,STRING_AGG(sg_users.first_name, ',') AS Open_RoleUserListNames
				,STRING_AGG(LEFT(sg_users.first_name, 1), ',') AS Open_RoleUserListInitials
				FROM (  
					SELECT DISTINCT ISNULL(FixedMapping_Usergroup_SelectedUserID, CASE WHEN FixedMapping_UsergroupID IS NULL THEN FixedMapping_UserID ELSE NULL END) AS UserID 
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					INNER JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
						ON stage_roles.LibraryID = wf.LibraryID 
						AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
						AND stage_roles.StageCode = open_stage.Open_StageCode
						AND stage_roles.StageIterationNo = open_stage.Open_Iteration
						AND RST_IsOpen = 1 
						AND RST_IsSkipping = 0
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					AND wf_r2u_map.RoleCode = stage_roles.RoleCode
				) wf_users
				INNER JOIN [1i00_SmarterWare]..sg_users sg_users ON sg_users.userid = 	wf_users.UserID
				WHERE wf_users.UserID IS NOT NULL AND wf_users.UserID <> ''
			) open_stage_user_list

			CROSS APPLY (
				Select ISNULL((
					Select ISNULL(sg_users.first_name + ' ' + sg_users.last_name, ' - ') as ApprName,'Manager' AS Role,
						LEFT(sg_users.first_name, 1) AS Initial
					FROM 
					(
						SELECT DISTINCT ISNULL(FixedMapping_Usergroup_SelectedUserID, CASE WHEN FixedMapping_UsergroupID IS NULL THEN FixedMapping_UserID ELSE NULL END) UserID			
						FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
						INNER JOIN [1i00_Central].[dbo].[WFS_Item_Stage_Iteration_RoleSections_Track] AS stage_roles 
						ON stage_roles.LibraryID = wf.LibraryID 
						AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
						AND stage_roles.StageCode = open_stage.Open_StageCode
						AND stage_roles.StageIterationNo = open_stage.Open_Iteration
						AND RST_IsOpen = 1 
						AND RST_IsSkipping = 0
						INNER JOIN  [1i00_Central].[dbo].[WFS_WorkFlowType_Roles] wf_roles 
						ON wf_r2u_map.RoleCode = wf_roles.RoleCode 
						AND wf_r2u_map.WorkFlowTypeCode = wf_roles.WorkFlowTypeCode  
						AND wf_roles.Role_Description = 'Job Manager'
						WHERE wf_r2u_map.LibraryID = wf.LibraryID
						AND wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					) AS wf_ApproverData
					LEFT JOIN [1i00_SmarterWare]..sg_users sg_users ON sg_users.userid = 	wf_ApproverData.UserID
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				) ,'{"ApprName":" - ","Role":"Manager","Initial":" - "}') AS wf_Approver
			) open_stage_Aprover

			CROSS APPLY (
				SELECT STRING_AGG(UserGroupID, ',') AS Open_RoleUserGroupList FROM (
					SELECT DISTINCT FixedMapping_UsergroupID AS UserGroupID
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					INNER JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
						ON stage_roles.LibraryID = wf.LibraryID 
						AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
						AND stage_roles.StageCode = open_stage.Open_StageCode
						AND stage_roles.StageIterationNo = open_stage.Open_Iteration
						AND RST_IsOpen = 1 
						AND RST_IsSkipping = 0
					WHERE wf_r2u_map.LibraryID = wf.LibraryID
					AND wf_r2u_map.ItemSeqNo = wf.ItemSeqNo
					AND wf_r2u_map.RoleCode = stage_roles.RoleCode
				) wf_usergroups
				WHERE UsergroupID IS NOT NULL
					AND UsergroupID <> ''
			) open_stage_user_group_list


			CROSS APPLY (
				SELECT STRING_AGG(StageCode,',') AS StageCodeList FROM [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
				WHERE stage_track.LibraryID = wf.LibraryID
				AND stage_track.ItemSeqNo = wf.ItemSeqNo
			) stages

			/*cross apply display fields after filters have applied*/
			CROSS APPLY (
				SELECT 
					Item_Resource_RUID,
					'/cfm/SmartGate/Applications/ColdRTI/getImage.cfm?r=1&ruid='+cast(Item_Resource_RUID as varchar(50))+'&IsAjax=true&bin=1' AS fileImage, 
					Item_wf_StartDate,
					FORMAT(Item_wf_StartDate, 'dd MMM yyyy') AS startDate,
					Item_wf_IntermediateDate,
					FORMAT(Item_wf_IntermediateDate, 'dd MMM yyyy') AS proofTime,
					Item_wf_DueDate,
					FORMAT(Item_wf_DueDate, 'dd MMM yyyy') AS endDate,
					Item_wf_DueTime,
					Item_wf_Objective,
					Item_wf_TextNote,
					ISNULL(NULLIF((Item_StandardClassifier_Barcode),''),' - ') AS Item_StandardClassifier_Barcode,
					ISNULL(NULLIF((Item_StandardClassifier_ProductCode),''),' - ') AS Item_StandardClassifier_ProductCode,
					ISNULL(NULLIF((Item_StandardClassifier_ArtworkNumber),''),' - ') AS Item_StandardClassifier_ArtworkNumber,
					wf_core.ItemSeqNo,
					wf_type.*,
					folder.*,
					m5_classifiers.*,
					tags.*,
					CONCAT('["', Folder_Division, '", "', Folder_Brand, '", "', Folder_SubBrand, '", "', Folder_Group, '", "', Folder_SubGroup, '"]') AS categories
					,CASE WHEN Item_OnHold = 1 THEN 'onhold'
						WHEN Item_Status = 0 THEN 'future'
						WHEN Item_Status >= 2 OR Item_Status = -2 THEN 'completed'
						WHEN ( 1=0
								OR Item_Status = 1 
								OR Item_Status = -1
								OR wf_type.WFS_CorrectedProofToDo = 1
								OR wf_type.WFS_CopyFilesToDAMBinsPostFinish = 'ToDo'
								) AND wf_status.HasTodo = 1
							THEN 'ToDo'
						WHEN Item_Status = 1 OR Item_Status = -1 THEN 'active'
						WHEN wf.Item_wf_DueDate < GETDATE() THEN 'overdue'
						WHEN Item_is_deleted = 1 AND Item_is_archived = 0 THEN 'deleted'
					END AS status
				FROM [1i00_Central].dbo.[i00wf_Item] AS wf_core

				CROSS APPLY (
					SELECT 
						WFS_WorkFlowTypeCode AS Type_Code,
						wf_type.WorkFlowType_Description AS Type_Desc,
						WFS_CorrectedProofToDo,
						WFS_CopyFilesToDAMBinsPostFinish
					FROM [1i00_Central].[dbo].[WFS_Task] wf_task
					INNER JOIN [1i00_Central].[dbo].[WFS_WorkFlowType] wf_type
					ON wf_task.LibraryID = wf_core.LibraryID
					AND wf_task.ItemSeqNo = wf_core.ItemSeqNo
					AND wf_task.WFS_WorkFlowTypeCode = wf_type.WorkFlowTypeCode
				) wf_type 

				CROSS APPLY (

						SELECT TD.ItemSeqNo,
						MAX(CASE WHEN ToDoOrActiveOrCompleted = 'ToDo' THEN 1 ELSE 0 END) AS HasToDo,
						MAX(CASE WHEN ToDoOrActiveOrCompleted = 'Active' THEN 1 ELSE 0 END) AS HasActive,
						MAX(CASE WHEN ToDoOrActiveOrCompleted = 'Completed' THEN 1 ELSE 0 END) AS HasCompleted
					FROM	[1i00_Central]..WFS_Item_ToDo TD
						INNER JOIN [1i00_Central]..WFS_Item_ToDo_Roles TDR ON TDR.ItemSeqNo = TD.ItemSeqNo
						AND TDR.LibraryID = TD.LibraryID
					WHERE	TD.LibraryID = wf_core.LibraryID
					AND		TD.ItemSeqNo = wf_core.ItemSeqNo
					GROUP BY TD.ItemSeqNo
				) wf_status

				CROSS APPLY (
					SELECT 
						catalogue_no AS Folder_ID
						,description AS Folder_Desc
						,description_long AS Folder_Desc_Long
						,IsWFJobBag AS Folder_IsWFJobBag
						,ISNULL((
							SELECT 
								DivisionName 
							FROM [dbo].[i00L_Divisions] 
							WHERE DivisionCode = folders.i00division
						),' - ') AS Folder_Division
						,ISNULL((
							SELECT 
								BrandDesc 
							FROM [dbo].[i00L_Brands] 
							WHERE BrandID = folders.Brand
						),' - ') AS Folder_Brand
						,ISNULL((
							SELECT
								SubBrandDesc
							FROM [dbo].[i00L_SubBrands]
							WHERE SubBrandID = folders.SubBrand
						),' - ') AS Folder_SubBrand
						,ISNULL((
							SELECT 
								GroupDesc 
							FROM [dbo].[i00L_Groups] 
							WHERE GroupID = folders.PrGroup
						),' - ') AS Folder_Group
						,ISNULL((
							SELECT 
								SubGroupDesc 
							FROM [dbo].[i00L_SubGroups] 
							WHERE SubGroupID = folders.SubGroup
						),' - ') AS Folder_SubGroup
					FROM [dbo].[i00L_ProductRecord] folders
					INNER JOIN [dbo].[i00L_ProdRes_m2m] project_m2m
					ON project_m2m.product_catalogue_no = folders.catalogue_no
					WHERE project_m2m.resource_RUID = wf_core.Item_Resource_RUID
				) folder

				CROSS APPLY (
					SELECT (
						SELECT 
							NULLIF(folders.i00division, '') AS 'Division.Code'
							,ISNULL((
								SELECT
									DivisionName 
								FROM [dbo].[i00L_Divisions] 
								WHERE DivisionCode = folders.i00division
							), ' - ') AS 'Division.Name'

							,NULLIF(folders.Brand, '') AS 'Brand.Code'
							,ISNULL((
								SELECT 
									BrandDesc 
								FROM [dbo].[i00L_Brands] 
								WHERE BrandID = folders.Brand
							), ' - ') AS 'Brand.Name'

							,NULLIF(folders.SubBrand, '') AS 'SubBrand.Code'
							,ISNULL((
								SELECT
									SubBrandDesc
								FROM [dbo].[i00L_SubBrands]
								WHERE SubBrandID = folders.SubBrand
							),' - ') AS 'SubBrand.Name'

							,NULLIF(folders.PrGroup, '') AS 'Group.Code'
							,ISNULL((
								SELECT 
									GroupDesc 
								FROM [dbo].[i00L_Groups] 
								WHERE GroupID = folders.PrGroup
							),' - ') AS 'Group.Name'

							,NULLIF(folders.SubGroup, '') AS 'SubGroup.Code'
							,ISNULL((
								SELECT 
									SubGroupDesc 
								FROM [dbo].[i00L_SubGroups] 
								WHERE SubGroupID = folders.SubGroup
							),' - ') AS 'SubGroup.Name'
						FROM [dbo].[i00L_ProductRecord] folders
						INNER JOIN [dbo].[i00L_ProdRes_m2m] project_m2m
						ON project_m2m.product_catalogue_no = folders.catalogue_no
						WHERE project_m2m.resource_RUID = wf_core.Item_Resource_RUID 
						FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
					) AS m5_classfiers
				) m5_classifiers

				OUTER APPLY (
					SELECT ISNULL((
						SELECT tag.TagID AS ID, TagDesc AS [Name] FROM [dbo].[i00L_Tag] tag
						INNER JOIN [dbo].[i00L_Tag_M2M] tag_m2m
						ON tag.TagID = tag_m2m.TagID
						AND tag_m2m.ItemSeqNo = wf_core.ItemSeqNo
						FOR JSON PATH
					), '[]') AS tags
				) tags

				WHERE wf_core.LibraryID = wf.LibraryID
					AND wf_core.ItemSeqNo = wf.ItemSeqNo
			
			) workflow_fields

			OUTER APPLY (
				SELECT SUM(
					CASE WHEN Stage_finished = 1 OR Stage_was_skipped = 1 THEN 1 ELSE 0 END
				) AS finished_stages,
				COUNT( StageCode ) AS total_stages
				FROM  [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
				WHERE stage_track.LibraryID = wf.LibraryID
				AND stage_track.ItemSeqNo = wf.ItemSeqNo
			) stage_progress


			OUTER APPLY (
				SELECT SUM(
					CASE WHEN RoleSection_DateOut IS NOT NULL OR RST_IsSkipping = 1 THEN 1 ELSE 0 END
				) AS finished_roles,
				COUNT( RoleCode ) AS total_roles
				
				FROM [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
				WHERE stage_roles.LibraryID = wf.LibraryID
					AND stage_roles.ItemSeqNo = wf.ItemSeqNo 
					AND stage_roles.StageCode = open_stage.Open_StageCode
					AND stage_roles.StageIterationNo = open_stage.Open_Iteration
			) open_stage_progress

			WHERE 1=1
				<cfif filter_by_workflow_seqno_list>
					AND wf.ItemSeqNo IN (<cfqueryparam value="#search_arguments.item_seqno_list#" cfsqltype="CF_SQL_INTEGER" list="true">)
				</cfif>

				<!--- Barcode/ProductCode/ArtworkNumber - Standard Classifier --->
				<cfloop array="#standard_classifier_filters#" index="i" item="currentType">
					AND wf.Item_StandardClassifier_#currentType# = <cfqueryparam value="#search_arguments[currentType]#" cfsqltype="cf_sql_varchar">
				</cfloop>

				<cfif filter_by_tags>
					AND EXISTS (
						SELECT TOP 1 1 
						FROM [dbo].[i00L_Tag] tag
						INNER JOIN [dbo].[i00L_Tag_M2M] tag_m2m
						ON tag.TagID = tag_m2m.TagID
						WHERE tag_m2m.ItemSeqNo = wf.ItemSeqNo
						AND tag.TagID IN ( <cfqueryparam value="#search_arguments.tag_id_list#" cfsqltype="CF_SQL_INTEGER" list="true"> )
					)
				</cfif>


				<cfif filter_by_keywords>
					AND 
					(
						
						1 = 0
						OR		wf.Item_wf_Objective LIKE '%#keywords#%'
						OR		workflow_fields.Folder_Desc LIKE '%#Trim(keywords)#%'
						OR		workflow_fields.Folder_Brand LIKE '%#Trim(keywords)#%'
						OR		workflow_fields.Folder_SubBrand LIKE '%#Trim(keywords)#%'
						OR		workflow_fields.Folder_Group LIKE '%#Trim(keywords)#%'
						OR		workflow_fields.Folder_SubGroup LIKE '%#Trim(keywords)#%'
						OR wf.Item_wf_TextNote LIKE '%#Trim(keywords)#%'

						OR		wf.ItemSeqNo LIKE '%#Trim(keywords)#%'
						OR		wf.Item_wf_client_reference LIKE '%#Trim(keywords)#%'
						OR		wf.Item_ItemCode LIKE '%#Trim(keywords)#%'

						<cfloop list="A,B,C" index="currentLetter">
							OR		wf.Item_ClientCode#currentLetter# LIKE '%#Trim(keywords)#%'
						</cfloop>
						<cfloop list="barcode,productCode,artworkNumber,fileSupplierRef" index="currentType">
							OR		wf.Item_StandardClassifier_#currentType# LIKE <cfqueryparam value="%#Trim(keywords)#%" cfsqltype="cf_sql_varchar">
						</cfloop>

						
					)
				</cfif>
				<Cfif StructKeyExists(search_arguments, "typeCode") and search_arguments.typeCode neq "">
					AND workflow_fields.Type_Code = <cfqueryparam value="#search_arguments.typeCode#" cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<Cfif search_arguments.showOverDue OR search_arguments.showOnHold OR search_arguments.showDeleted>
					AND ( 1=0
						<cfif search_arguments.showOverDue>
							OR status = 'overdue'
						</cfif>
						<cfif search_arguments.showOnHold>
							OR status = 'onhold'
						</cfif>
						<cfif search_arguments.showDeleted>
							OR status = 'deleted'
						</cfif>
					)
				</cfif>

			<!---
			WHERE NOT (Open_RoleUserList IS NULL AND Open_RoleUserGroupList IS NULL)
			--->
			Order by workflow_fields.ItemSeqNo desc

		</cfquery>
			<cfcatch type="any">
				<cfreturn cfcatch>
			</cfcatch>
		</cftry>

		<cfscript>
			offset = 1;
			slice_size = 50;

			result_count = arr_workflows.len();

			if( slice_size > result_count - (offset - 1) ){
				slice_size = result_count - (offset - 1);
			}

			if(slice_size gt 0){
				workflows = arr_workflows;
			} else {
				workflows = arr_workflows;
			}
		</cfscript>

		
		<cfreturn {
			_result_count: arr_workflows.len(),
			workflows: workflows,
		}>
	</cffunction>

	<!--- LL TODO 2024-07-23 this should be moved to the core/assets.cfc component --->
	<cffunction  name="getDamAssetsList" access="public" returntype="array" output="false">
		<cfargument name="jwtData" type="struct">

		<cfquery name="arr_DamAssets" returntype="array" datasource="#arguments.jwtData.sessions.library_context.LibraryODBCsource#">
			SELECT  DISTINCT top 40 
				i00l_resourcerecord.ruid id,
				i00l_resourcerecord.libraryid,
				i00l_resourcerecord.rcodeinlibrary,
				i00l_resourcerecord.rdescription AS name,
				'/cfm/SmartGate/Applications/ColdRTI/getImage.cfm?r=1&ruid='+cast(i00l_resourcerecord.ruid as varchar(50))+'&IsAjax=true' AS image,
				isnull(i00l_resourcerecord.standardclassifier_productcode,' - ') AS productCode,
				isnull(i00l_resourcerecord.standardclassifier_artworknumber,' - ') AS artworkNumber,
				isnull(i00l_resourcerecord.standardclassifier_barcode,' - ') AS barcode,
				FORMAT(i00l_resourcerecord.rdatecreated, 'dd MMM yyyy') AS [date],
				i00l_resourcerecord.rdatecreated,
				isnull(i00l_brands.branddesc,' - ') AS brand
			FROM   i00l_resourcerecord
			LEFT JOIN i00l_prodres_m2m ON i00l_resourcerecord.ruid = i00l_prodres_m2m.resource_ruid
			LEFT JOIN i00l_productrecord ON i00l_prodres_m2m.product_catalogue_no = i00l_productrecord.catalogue_no
			LEFT JOIN i00l_brands ON i00l_productrecord.brand = i00l_brands.brandid
			LEFT JOIN [1i00_Central]..i00use_libcustusergroup_m2m ON [1i00_Central]..i00use_libcustusergroup_m2m.customerid = '#arguments.jwtData.sessions.userid#'
			AND [1i00_Central]..i00use_libcustusergroup_m2m.libraryid = '#arguments.jwtData.sessions.LibraryID#'
			order by i00l_resourcerecord.rdatecreated DESC
		</cfquery>
		
		<cfreturn arr_DamAssets>
	</cffunction>

	<cffunction access="public" name="getFolderWorkflowList" returntype="array">
		<cfargument name="folder_id" type="any">
		<cfargument name="user_id" type="string">
		<cfargument name="jwtData" type="struct">
		<cfargument  name="isOnlyMine" type="boolean" required="false" default="true">
		

		<!--- <cfquery name="arr_workflows" returntype="array" datasource="#request.dsns.onei00maindb#"> --->
		<cfquery name="arr_folderworkflows" returntype="array" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">
			DECLARE @UserID NVARCHAR(100) = <cfqueryparam value="#arguments.user_id#" cfsqltype="CF_SQL_VARCHAR">
					

			SELECT 
				Item_Resource_RUID,
				wf_core.Item_wf_Objective,
				CASE WHEN Item_OnHold = 1 THEN '/images/start-icon.png'
					WHEN Item_Status = 0 THEN '/images/measure-icon.png'
					WHEN Item_Status >= 2 OR Item_Status = -2 THEN '/images/check-icon.png'
					WHEN Item_Status = 1 OR Item_Status = -1 THEN '/images/play-icon.png'
				END AS icon,
				CASE WHEN Item_OnHold = 1 THEN 'onhold'
					WHEN Item_Status = 0 THEN 'future'
					WHEN Item_Status >= 2 OR Item_Status = -2 THEN 'completed'
					WHEN Item_Status = 1 OR Item_Status = -1 THEN 'active'
				END AS status,
				wf_type.Type_Desc,
				open_stage.Open_StageDesc,
				concat('##',wf_core.ItemSeqNo) ItemSeqNo,
				'/cfm/SmartGate/Applications/ColdRTI/getImage.cfm?r=1&ruid='+cast(Item_Resource_RUID as varchar(50))+'&IsAjax=true' AS fileImage, 
				FORMAT(Item_wf_DueDate, 'dd MMM yyyy') AS endDate,
				FORMAT(Item_wf_StartDate, 'dd MMM yyyy') AS startDate,
				CONCAT('["', Folder_Division, '", "', Folder_Group, '", "', Folder_Brand, '"]') AS categories,
				CAST(((CAST(finished_stages AS float)+(CAST(finished_roles AS float)/CAST(total_roles AS float)))/CAST(total_stages AS float)) * 100 AS INT) AS total_progress,
				ISNULL(NULLIF((Item_StandardClassifier_Barcode),''),' - ') AS Item_StandardClassifier_Barcode,
				ISNULL(NULLIF((Item_StandardClassifier_ProductCode),''),' - ') AS Item_StandardClassifier_ProductCode,
				ISNULL(NULLIF((Item_StandardClassifier_ArtworkNumber),''),' - ') AS Item_StandardClassifier_ArtworkNumber,
				open_stage_user_list.*,
				folder.*,
				open_stage_Aprover.*,
				open_stage.Open_StageSeqNo
				
			FROM [1i00_Central].dbo.[i00wf_Item] AS wf_core
			
			CROSS APPLY (
				SELECT 
					catalogue_no AS Folder_ID
					,description AS Folder_Desc
					,description_long AS Folder_Desc_Long
					,IsWFJobBag AS Folder_IsWFJobBag
					,ISNULL((
						SELECT 
							DivisionName 
						FROM [dbo].[i00L_Divisions] 
						WHERE DivisionCode = folders.i00division
					),' - ') AS Folder_Division
					,ISNULL((
						SELECT 
							BrandDesc 
						FROM [dbo].[i00L_Brands] 
						WHERE BrandID = folders.Brand
					),' - ') AS Folder_Brand
					,ISNULL((
						SELECT
							SubBrandDesc
						FROM [dbo].[i00L_SubBrands]
						WHERE BrandID = folders.Brand
						AND SubBrandID = folders.SubBrand
					),' - ') AS Folder_SubBrand
					,ISNULL((
						SELECT 
							GroupDesc 
						FROM [dbo].[i00L_Groups] 
						WHERE GroupID = folders.PrGroup
					),' - ') AS Folder_Group
					,ISNULL((
						SELECT 
							SubGroupDesc 
						FROM [dbo].[i00L_SubGroups] 
						WHERE GroupID = folders.PrGroup
						AND SubGroupID = folders.SubGroup
					),' - ') AS Folder_SubGroup
				FROM [dbo].[i00L_ProductRecord] folders
				INNER JOIN [dbo].[i00L_ProdRes_m2m] project_m2m
				ON project_m2m.product_catalogue_no = folders.catalogue_no
				WHERE project_m2m.resource_RUID = wf_core.Item_Resource_RUID
			) folder
			CROSS APPLY (
				SELECT 
					WFS_WorkFlowTypeCode AS Type_Code,
					wf_type.WorkFlowType_Description AS Type_Desc
				FROM [1i00_Central].[dbo].[WFS_Task] wf_task
				INNER JOIN [1i00_Central].[dbo].[WFS_WorkFlowType] wf_type
				ON wf_task.LibraryID = wf_core.LibraryID
				AND wf_task.ItemSeqNo = wf_core.ItemSeqNo
				AND wf_task.WFS_WorkFlowTypeCode = wf_type.WorkFlowTypeCode
			) wf_type
			<Cfif arguments.isOnlyMine>
				CROSS APPLY (
					SELECT TOP 1 UserID AS FilteredByUser
					FROM ( 
						SELECT ISNULL(FixedMapping_Usergroup_SelectedUserID, FixedMapping_UserID) AS UserID 
						FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
						WHERE wf_r2u_map.LibraryID = wf_core.LibraryID
						AND	wf_r2u_map.ItemSeqNo = wf_core.ItemSeqNo
					) wf_users
					WHERE UserID = @UserID
				) has_user_in_role_filter
			</Cfif>

			CROSS APPLY (
				SELECT StageCode AS Open_StageCode, 
				stage_track.Stage_started,
				stage_track.Stage_finished,
				stage_track.Stage_was_skipped,
				Stage_current_iteration AS Open_Iteration,
				(
					SELECT  Stage_Description 
					FROM [1i00_Central].[dbo].[WFS_WorkFlowType_Stages] stages
					WHERE stages.StageCode = stage_track.StageCode
					AND stages.WorkFlowTypeCode = stage_track.WorkFlowTypeCode
				) AS Open_StageDesc,
				(
					SELECT Stage_SeqNo
					FROM [1i00_Central].[dbo].[WFS_WorkFlowType_Stages] stages
					WHERE stages.StageCode = stage_track.StageCode
					AND stages.WorkFlowTypeCode = stage_track.WorkFlowTypeCode
				) AS Open_StageSeqNo
				FROM [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
				WHERE stage_track.LibraryID = wf_core.LibraryID
				AND stage_track.ItemSeqNo = wf_core.ItemSeqNo
				AND stage_track.Stage_started = 1
				AND stage_track.Stage_finished = 0
				AND stage_track.Stage_was_skipped = 0
			) open_stage

			OUTER APPLY (
				SELECT SUM(
					CASE WHEN Stage_finished = 1 OR Stage_was_skipped = 1 THEN 1 ELSE 0 END
				) AS finished_stages,
				COUNT( StageCode ) AS total_stages
				FROM  [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
				WHERE stage_track.LibraryID = wf_core.LibraryID
				AND stage_track.ItemSeqNo = wf_core.ItemSeqNo
			) stage_progress

			OUTER APPLY (
				SELECT SUM(
					CASE WHEN RoleSection_DateOut IS NOT NULL OR RST_IsSkipping = 1 THEN 1 ELSE 0 END
				) AS finished_roles,
				COUNT( RoleCode ) AS total_roles
							
				FROM [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
				WHERE stage_roles.LibraryID = wf_core.LibraryID
					AND stage_roles.ItemSeqNo = wf_core.ItemSeqNo 
					AND stage_roles.StageCode = open_stage.Open_StageCode
					AND stage_roles.StageIterationNo = open_stage.Open_Iteration
			) open_stage_progress

			CROSS APPLY (
				SELECT STRING_AGG(wf_users.UserID, ',') AS Open_RoleUserList
				,STRING_AGG(sg_users.first_name, ',') AS Open_RoleUserListNames
				,STRING_AGG(LEFT(sg_users.first_name, 1), ',') AS Open_RoleUserListInitials
				FROM (  
					SELECT DISTINCT ISNULL(FixedMapping_Usergroup_SelectedUserID, CASE WHEN FixedMapping_UsergroupID IS NULL THEN FixedMapping_UserID ELSE NULL END) AS UserID 
					FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
					INNER JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
						ON stage_roles.LibraryID = wf_core.LibraryID 
						AND stage_roles.ItemSeqNo = wf_core.ItemSeqNo 
						AND stage_roles.StageCode = open_stage.Open_StageCode
						AND stage_roles.StageIterationNo = open_stage.Open_Iteration
						AND RST_IsOpen = 1 
						AND RST_IsSkipping = 0
					WHERE wf_r2u_map.LibraryID = wf_core.LibraryID
					AND wf_r2u_map.ItemSeqNo = wf_core.ItemSeqNo
					AND wf_r2u_map.RoleCode = stage_roles.RoleCode
				) wf_users
				INNER JOIN [1i00_SmarterWare]..sg_users sg_users ON sg_users.userid = 	wf_users.UserID
				WHERE wf_users.UserID IS NOT NULL AND wf_users.UserID <> ''
			) open_stage_user_list

			CROSS APPLY (
				Select ISNULL((
					Select ISNULL(sg_users.first_name + ' ' + sg_users.last_name, ' - ') as ApprName,'Manager' AS Role,
						LEFT(sg_users.first_name, 1) AS Initial
					FROM 
					(
						SELECT DISTINCT ISNULL(FixedMapping_Usergroup_SelectedUserID, CASE WHEN FixedMapping_UsergroupID IS NULL THEN FixedMapping_UserID ELSE NULL END) UserID			
						FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
						INNER JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles 
						ON stage_roles.LibraryID = wf_core.LibraryID 
						AND stage_roles.ItemSeqNo = wf_core.ItemSeqNo 
						AND stage_roles.StageCode = open_stage.Open_StageCode
						AND stage_roles.StageIterationNo = open_stage.Open_Iteration
						AND RST_IsOpen = 1 
						AND RST_IsSkipping = 0
						INNER JOIN  [1i00_Central].[dbo].[WFS_WorkFlowType_Roles] wf_roles 
						ON wf_r2u_map.RoleCode = wf_roles.RoleCode 
						AND wf_r2u_map.WorkFlowTypeCode = wf_roles.WorkFlowTypeCode  
						AND wf_roles.Role_Description = 'Job Manager'
						WHERE wf_r2u_map.LibraryID = wf_core.LibraryID
						AND wf_r2u_map.ItemSeqNo = wf_core.ItemSeqNo
					) AS wf_ApproverData
					LEFT JOIN [1i00_SmarterWare]..sg_users sg_users ON sg_users.userid = 	wf_ApproverData.UserID
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				) ,'{"ApprName":" - ","Role":"Manager","Initial":" - "}') AS wf_Approver
			) open_stage_Aprover

			WHERE wf_core.LibraryID = #jwtData.SESSIONS.libraryid#
			AND Folder_ID IN (#listQualify(arguments.folder_id, "'")#)
			Order by Open_StageSeqNo
		</cfquery>
		<cfreturn arr_folderworkflows>
	</cffunction>

	<cffunction  access="public" name="getStagesData" returntype="array">
		<cfargument name="itemSeqNo" type="string">
		<cfargument name="jwtData" type="struct">

		<!--- <cfquery name="arr_workflows" returntype="array" datasource="#request.dsns.onei00maindb#"> --->
		<cfquery name="arr_workflowsStages" returntype="array" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">
			DECLARE @itemSeqNo NVARCHAR(100) = <cfqueryparam value="#arguments.itemSeqNo#" cfsqltype="CF_SQL_VARCHAR">;
			WITH StageData AS (
				SELECT 
					CASE
						WHEN Stage_finished = 1 THEN 'Completed'
						WHEN Stage_started = 1 THEN 'Current'
						ELSE 'Pending'
					END AS Stage_Desc,
					CASE
						WHEN Stage_finished = 1 THEN '/images/check-icon.png'
						WHEN Stage_started = 1 THEN '/images/play-icon.png'
						ELSE '/images/measure-icon.png'
					END AS StageIcons,
					T.WFS_WorkFlowTypeCode,
					T.WFS_StageCode,
					W.WorkflowtypeCode,
					W.Workflowtype_Description,
					W.WorkFlowType_UsageNote,
					S.StageCode,
					S.Stage_Description,
					S.Stage_Definition,
					S.Stage_SeqNo,
					S.Stage_DisplaySeqNo,
					S.Stage_IsAuxiliary,
					S.Stage_IsDesignArt,
					S.Stage_IsTechnicalProof,
					S.Stage_IsFinalCorrectedProof,
					S.Stage_IsRequiringRoleSectionsPrioritization,
					S.Stage_GroupNumberAtWhichToNotifyObservers,
					ISNULL(ST.Stage_Status, 0) AS Stage_Status,
					ISNULL(ST.Stage_Started, 0) AS Stage_Started,
					ISNULL(Stage_Estimated_CalendarWeeks,0) AS Stage_Estimated_CalendarWeeks,
					COALESCE(ST.Stage_Started_dt, LAG(ISNULL(ST.Stage_finished_dt, DATEADD(wk, S.Stage_Estimated_CalendarWeeks, ST.Stage_started_dt)), 1) OVER (PARTITION BY T.WFS_WorkFlowTypeCode ORDER BY S.Stage_SeqNo)) AS Stage_Started_dt,
					ST.Stage_finished,
					CASE 
						WHEN ISNULL(ST.Stage_Started_dt, '') = '' THEN  
							DATEADD(wk, ISNULL(Stage_Estimated_CalendarWeeks,0), LAG(ISNULL(ST.Stage_finished_dt, DATEADD(wk, ISNULL(Stage_Estimated_CalendarWeeks,0), ST.Stage_started_dt)), 1) OVER (PARTITION BY T.WFS_WorkFlowTypeCode ORDER BY S.Stage_SeqNo))
						ELSE ISNULL(ST.Stage_finished_dt, DATEADD(wk, ISNULL(Stage_Estimated_CalendarWeeks,0), ST.Stage_Started_dt))
					END AS Stage_finished_dt,
					ST.Stage_current_iteration,
					ST.Stage_AwaitingFinancialApproval_Key,
					ISNULL(ST.Stage_was_skipped, 0) AS Stage_was_skipped,
					ST.Stage_was_skipped_dt,
					ST.Stage_was_skipped_by_userid,
					StageApproverData.ApproverName,
					StageApproverData.ApproverInitial,
					open_stage_user_list.*,
					CAST(((CAST(finished_stages AS float)+(CAST(finished_roles AS float)/CAST(total_roles AS float)))/CAST(total_stages AS float)) * 100 AS INT) AS total_progress,
					ROW_NUMBER() OVER (PARTITION BY T.WFS_WorkFlowTypeCode, T.WFS_StageCode ORDER BY ST.Stage_finished_dt DESC) AS RowNum
				FROM
					[1i00_Central]..WFS_Task T
				JOIN [1i00_Central]..WFS_WorkFlowType W ON W.WorkFlowTypeCode = T.WFS_WorkFlowTypeCode
				JOIN [1i00_Central]..WFS_WorkflowType_Stages S ON S.WorkflowtypeCode = T.WFS_WorkFlowTypeCode AND S.Stage_IsActive = 1
				LEFT JOIN [1i00_Central]..WFS_Item_Stages_Track ST ON (T.LibraryID = ST.LibraryID) AND (T.ItemSeqNo = ST.ItemSeqNo) AND S.WorkflowtypeCode = ST.WorkflowtypeCode AND S.StageCode = ST.StageCode
				CROSS APPLY (
					SELECT DISTINCT WorkFlowTypeCode, StageCode, StageRole_IsStageApprover, RoleCode,
						RoleInfo.*, ROLES.*
					FROM [1i00_Central].[dbo].[WFS_WorkflowType_Stage_Role_m2m] rc
					OUTER APPLY (
						SELECT Role_Description FROM [1i00_Central].[dbo].[WFS_WorkFlowType_Roles]
						WHERE [1i00_Central].[dbo].[WFS_WorkFlowType_Roles].[RoleCode] = rc.[RoleCode]
					) RoleInfo
					CROSS APPLY (
						SELECT sg_users.first_name + ' ' + sg_users.last_name AS ApproverName, LEFT(sg_users.first_name, 1) AS ApproverInitial
						FROM (
							SELECT DISTINCT ISNULL(NULLIF((FixedMapping_Usergroup_SelectedUserID), ''), CASE WHEN ISNULL(NULLIF(FixedMapping_UsergroupID, ''), '') = '' THEN FixedMapping_UserID ELSE NULL END) USERID
							FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
							WHERE 1 = 1
							AND RoleCode = rc.RoleCode
							AND ItemSeqNo = T.ItemSeqNo
							AND WorkFlowTypeCode = T.WFS_WorkFlowTypeCode
						) Approver
						LEFT JOIN [1i00_SmarterWare]..sg_users sg_users ON sg_users.userid = Approver.UserID
					) AS ROLES
					WHERE StageRole_IsStageApprover = 1
					AND WorkFlowTypeCode = T.WFS_WorkFlowTypeCode
					AND StageCode = S.StageCode
				) StageApproverData
				CROSS APPLY (
					SELECT STRING_AGG(wf_users.UserID, ',') AS Open_RoleUserList,
						STRING_AGG(sg_users.first_name, ',') AS Open_RoleUserListNames,
						STRING_AGG(LEFT(sg_users.first_name, 1), ',') AS Open_RoleUserListInitials
					FROM (
						SELECT DISTINCT ISNULL(NULLIF((FixedMapping_Usergroup_SelectedUserID), ''), CASE WHEN ISNULL(NULLIF(FixedMapping_UsergroupID, ''), '') = '' THEN FixedMapping_UserID ELSE NULL END) AS UserID 
						FROM [1i00_Central].[dbo].[WFS_Item_role2users_FixedMappings] wf_r2u_map
						INNER JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
							ON stage_roles.LibraryID = T.LibraryID 
							AND stage_roles.ItemSeqNo = T.ItemSeqNo 
							AND stage_roles.StageCode = ST.StageCode
							AND stage_roles.StageIterationNo = ST.Stage_current_iteration
							AND RST_IsOpen = 1 
							AND RST_IsSkipping = 0
						WHERE wf_r2u_map.LibraryID = T.LibraryID
						AND wf_r2u_map.ItemSeqNo = T.ItemSeqNo
						AND wf_r2u_map.RoleCode = stage_roles.RoleCode
					) wf_users
					INNER JOIN [1i00_SmarterWare]..sg_users sg_users ON sg_users.userid = wf_users.UserID
					WHERE wf_users.UserID IS NOT NULL AND wf_users.UserID <> ''
				) open_stage_user_list
				OUTER APPLY (
					SELECT SUM(
						CASE WHEN RoleSection_DateOut IS NOT NULL OR RST_IsSkipping = 1 THEN 1 ELSE 0 END
					) AS finished_roles,
					COUNT( RoleCode ) AS total_roles
										
					FROM [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS stage_roles
					WHERE stage_roles.LibraryID = '#arguments.jwtData.sessions.LibraryID#'
						AND stage_roles.ItemSeqNo = T.ItemSeqNo 
						AND stage_roles.StageCode = ST.StageCode
						AND stage_roles.StageIterationNo = ST.Stage_current_iteration
				) open_stage_progress
				OUTER APPLY (
					SELECT SUM(
						CASE WHEN Stage_finished = 1 OR Stage_was_skipped = 1 THEN 1 ELSE 0 END
					) AS finished_stages,
					COUNT( StageCode ) AS total_stages
					FROM  [1i00_Central].[dbo].[WFS_Item_Stages_Track] stage_track
					WHERE stage_track.LibraryID = '#arguments.jwtData.sessions.LibraryID#'
					AND stage_track.ItemSeqNo = T.ItemSeqNo
				) stage_progress
				WHERE
				T.ItemSeqNo = @itemSeqNo
				AND T.LibraryID = '#arguments.jwtData.sessions.LibraryID#'
				AND S.Stage_IsActive = 1
			),
			MaxRowNum AS (
				SELECT 
					WFS_WorkFlowTypeCode,
					WFS_StageCode,
					MAX(RowNum) AS MaxRowNum
				FROM StageData
				WHERE Stage_Desc = 'Completed'
				GROUP BY WFS_WorkFlowTypeCode, WFS_StageCode
			)
			SELECT *, 
				FORMAT(CASE 
					WHEN ISNULL(SD.Stage_Started_dt, '') = '' 
						THEN LAG(SD.Stage_finished_dt, 1) OVER (PARTITION BY SD.WFS_WorkFlowTypeCode ORDER BY Stage_SeqNo)
					ELSE Stage_Started_dt
				END, 'dd MMM yyyy') AS StartDate,
				FORMAT(CASE 
					WHEN ISNULL(SD.Stage_Started_dt, '') = '' 
						THEN  DATEADD(wk, ISNULL(SD.Stage_Estimated_CalendarWeeks,0), LAG(ISNULL(SD.Stage_finished_dt, DATEADD(wk, ISNULL(SD.Stage_Estimated_CalendarWeeks,0), SD.Stage_started_dt)), 1) OVER (PARTITION BY SD.WFS_WorkFlowTypeCode ORDER BY Stage_SeqNo))
					ELSE ISNULL(Stage_finished_dt,DATEADD(wk, ISNULL(SD.Stage_Estimated_CalendarWeeks,0), LAG(ISNULL(SD.Stage_finished_dt, DATEADD(wk, ISNULL(SD.Stage_Estimated_CalendarWeeks,0), SD.Stage_started_dt)), 1) OVER (PARTITION BY SD.WFS_WorkFlowTypeCode ORDER BY Stage_SeqNo)))
				END, 'dd MMM yyyy') AS EndDate
			FROM StageData SD
			LEFT JOIN MaxRowNum MRN
			ON SD.WFS_WorkFlowTypeCode = MRN.WFS_WorkFlowTypeCode
			AND SD.WFS_StageCode = MRN.WFS_StageCode
			AND SD.RowNum = MRN.MaxRowNum
			WHERE 
			(
				Stage_Desc <> 'Completed'
			)
			OR 
			(
				Stage_Desc = 'Completed' AND SD.RowNum = MRN.MaxRowNum
			)
			ORDER BY Stage_SeqNo ASC;


		</cfquery>
		<cfreturn arr_workflowsStages>
	</cffunction>

	<cffunction  access="public" name="getStagesByItemSeqNo" returntype="array" output="false">
		<cfargument  name="ItemSeqNo" type="string" required="true">
		<cfargument  name="jwtData" type="struct" required="true">
		
		<cfquery name="arr_workflowsStages" returntype="array" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">
			SELECT 
				CASE
					WHEN Stage_finished = 1 THEN 'Completed'
					WHEN Stage_started = 1 THEN 'Current'
					ELSE 'Pending'
				END AS Stage_Desc,
				CASE
					WHEN Stage_finished = 1 THEN '/images/check-icon.png'
					WHEN Stage_started = 1 THEN '/images/play-icon.png'
					ELSE '/images/measure-icon.png'
				END AS StageIcons,
				S.*,
				(
					SELECT SubStageCode, SubStage_Name
					FROM [1i00_Central]..WFS_WorkFlowType_SubStages
					WHERE 1=1 
					--WorkFlowTypeCode = T.WFS_WorkFlowTypeCode
					AND StageCode = S.StageCode
					ORDER BY StageCode, SubStage_Order
					FOR JSON PATH, INCLUDE_NULL_VALUES
				) AS SubStagesJson
			FROM
			[1i00_Central]..WFS_Task T
			JOIN [1i00_Central]..WFS_WorkFlowType W ON W.WorkFlowTypeCode = T.WFS_WorkFlowTypeCode
			JOIN [1i00_Central]..WFS_WorkflowType_Stages S ON S.WorkflowtypeCode = T.WFS_WorkFlowTypeCode AND S.Stage_IsActive = 1
			LEFT JOIN [1i00_Central]..WFS_Item_Stages_Track ST ON (T.LibraryID = ST.LibraryID) AND (T.ItemSeqNo = ST.ItemSeqNo) 
			AND S.WorkflowtypeCode = ST.WorkflowtypeCode AND S.StageCode = ST.StageCode
			WHERE T.ItemSeqNo = #arguments.ItemSeqNo#
			AND T.LibraryID = #arguments.jwtData.SESSIONS.libraryid#
			AND S.Stage_IsActive = 1
			ORDER BY Stage_SeqNo
		</cfquery>

		<cfreturn arr_workflowsStages>
	</cffunction>

	<cffunction access="public" name="getRolesData" returntype="array">
		<cfargument name="itemSeqNo" type="string">
		<cfargument name="itemSeqNo" type="string">
		<cfargument name="jwtData" type="struct">

	</cffunction>
	
	<cffunction access="public" name="getQuestionsListData" returntype="array">
		<cfargument  name="itemSeqNo" type="numeric" required="true">
		<cfargument  name="jwtData" type="struct" required="true">

		

		<cfquery name="rsSubStageData" returntype="array" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">
			WITH CTE AS 
			(
				SELECT
					T.LibraryID,
					T.ItemSeqNo,
					T.WFS_WorkFlowTypeCode,
					T.WFS_StageCode,
					T.WFS_DesignForPrepress_Filename_Saved,
					T.WFS_DesignForPrepress_Filename_Original,
					T.WFS_DesignForPrepress_PDF_Filename_Saved,
					T.WFS_DesignForPrepress_PDF_Filename_Original,
					T.WFS_Artwork_ID,
					T.WFS_RoleFinish_EmailStageApprover,
					ITEM.Item_StandardClassifier_Barcode,
					ITEM.Item_StandardClassifier_TUN,
					ITEM.Item_StandardClassifier_BarcodeType,
					ITEM.Item_StandardClassifier_ProductCode,
					ITEM.Item_StandardClassifier_ArtworkNumber,
					ITEM.Item_StandardClassifier_Dieline,
					ITEM.Item_StandardClassifier_FileSupplierRef,
					ITEM.Item_StandardClassifier_CountryOfOrigin,
					ITEM.Item_StandardClassifier_GPCBrickCode,
					ITEM.Item_StandardClassifier_WorkflowSubType,
					ITEM.Item_StandardClassifier_Material_BOM,
					ITEM.Item_StandardClassifier_FinishedArtProvider,
					ITEM.Item_StandardClassifier_Designer,
					ITEM.Item_StandardClassifier_PrePress,
					ITEM.Item_StandardClassifier_Printer,
					ITEM.Item_StandardClassifier_GLN,
					ITEM.Item_StandardClassifier_SmartMedia_Status,
					ITEM.Item_StandardClassifier_SmartMedia_FilenameMetadata,
					ITEM.Item_StandardClassifier_SmartMedia_AvailabilityDate_Start,
					ITEM.Item_StandardClassifier_SmartMedia_AvailabilityDate_End,
					ITEM.Item_StandardClassifier_SmartMedia_PromotionDate_Start,
					ITEM.Item_StandardClassifier_SmartMedia_PromotionDate_End,
					ITEM.Item_ItemCode,
					ITEM.Item_wf_Parent_SeqNo,
					ITEM.Item_alternateWFS_typeID,
					W.WorkFlowType_Description,
					W.WorkFlowType_RespCodeForFinArtWFFolderCode,
					W.WorkFlowType_CreateQuestionForFinArtWFFolderCode,
					W.WorkFlowType_ItemCodeForFinArtWFFolderCode,
					W.WorkFlowType_WFSSpecificType,
					W.WorkFlowType_AltWFS_TypeInsteadOfFirstFile,
					W.WorkFlowType_ShowOtherRolesLink,
					W.WorkFlowType_ShowCompanyWithUser,
					W.CreateDiffWFTypeOnFinish,
					W.WorkFlowType_UseFileUploadOptionalPreview,
					W.WorkFlowType_StageApproveWhenOneRoleFinish,
					W.WorkFlowType_StageApproveWhenTwoRoleFinish,
					W.WorkFlowType_StageApproveWhenThreeRoleFinish,
					W.WorkFlowType_AltWFS_CanStageApproveAltMethod,
					W.WorkFlowType_AltWFS_UseQuoteGroup,
					W.WorkFlowType_UseFDF,
					W.WorkFlowType_UseRemoteDirector,
					W.WorkFlowType_UseVProof,
					W.WorkFlowType_DAMOnStageFinish,
					W.WorkFlowType_DAMOnFinish,
					W.WorkflowType_DAMOnFinish_MakeOldMatchingItemCode,
					W.WorkflowType_DAMOnFinish_RequiresPendingUploadApproval,
					W.WorkFlowType_ResetAbstainEachStage,
					W.WorkflowType_ForceEmailDAMUploadOnFinish,
					W.WorkflowType_GeneralWorkflowComments,
					W.WorkflowType_UseStageApprActionComments,
					'' as WorkFlowType_StandardClassifier_Barcode_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_BarcodeType_SpecificValidation,
					W.WorkFlowType_StandardClassifier_ProductCode_SpecificValidation,
					W.WorkFlowType_StandardClassifier_ArtworkNumber_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_Dieline_SpecificValidation,
					W.WorkFlowType_StandardClassifier_FileSupplierRef_SpecificValidation,
					W.WorkFlowType_StandardClassifier_GPCBrickCode_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_WorkflowSubType_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_Material_BOM_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_FinishedArtProvider_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_Designer_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_PrePress_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_Printer_SpecificValidation,
					W.WorkFlowType_StandardClassifier_GLN_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_SmartMedia_Status_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_SmartMedia_FilenameMetadata_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_SmartMedia_AvailabilityDate_Start_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_SmartMedia_AvailabilityDate_End_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_SmartMedia_PromotionDate_Start_SpecificValidation,
					'' as WorkFlowType_StandardClassifier_SmartMedia_PromotionDate_End_SpecificValidation,
					SR.WorkFlowTypeCode,
					SR.StageCode,
					SR.RoleCode,
					SR.StageRole_hasGeneralRoleComments,
					SR.StageRole_displayTheAbstainOption,
					SR.StageRole_EmailMeFinishSummary,
					SR.StageRole_DontOpenEmailUserJustFinished,
					SR.StageRole_onlyInvolveWhenPreviousDone,
					SR.StageRole_onlyExposeWhenPreviousDone,
					SR.StageRole_GroupPrioritizationNumber,
					SR.StageRole_EmailPeriodStartOnceComplete,
					SR.StageRole_AllowFinishWhenOneRequiredRespDone,
					SR.StageRole_AllowFinishWhenRespCodeYes,
					SR.StageRole_EmailActionApproval,
					SR.StageRole_HasReferencePanel,
					SR.StageRole_MustViewMarkupFile,
					SR.StageRole_AskNewJobOnFinish,
					SR.StageRole_Email_SendTo_RoleCodes_RoleFinish,
					SR.StageRole_PreventUnfinishInSummary,
					S.Stage_Description,
					S.Stage_Definition,
					S.Stage_IsFinalApprovalPoint,
					S.Stage_SeqNo,
					S.Stage_DisplaySeqNo,
					S.Stage_IsMandatory,
					S.Stage_IsAuxiliary,
					S.Stage_IsDesignArt,
					S.Stage_IsTechnicalProof,
					S.Stage_IsFinalCorrectedProof,
					S.Stage_IsPrivate,
					S.Stage_IsRequiringRoleSectionsPrioritization,
					S.Stage_GroupNumberAtWhichToNotifyObservers,
					S.Stage_HasQuoteRequests,
					S.Stage_Email_RequestApproval_IncludeReferencePanel,
					S.Stage_Email_RequestApproval_IncludeReferencePanel_Iteration,
					S.Stage_Email_RequestApproval_IncludeCorrections,
					S.Stage_Email_RequestApproval_IncludeCorrections_Iteration,
					S.Stage_Email_Approved_IncludeReferencePanel,
					S.Stage_Email_Approved_IncludeCorrections,
					S.Stage_Email_Approved_SendToRoleCodes,
					ISNULL(ST.Stage_Status,0) AS Stage_Status,
					ISNULL(ST.Stage_Started,0) AS Stage_Started,
					ST.Stage_Started_dt,
					ST.Stage_finished,
					ST.Stage_finished_dt,
					ISNULL(ST.Stage_was_skipped,0) AS Stage_was_skipped,
					ST.Stage_was_skipped_dt,
					ST.Stage_was_skipped_by_userid,
					R.Role_Description,
					R.Role_IsWorkflowManager,
					R.Role_IsInitiator,
					R.Role_IsDesignProvider,
					R.Role_IsPrintingProvider,
					R.Role_IsObserver,
					R.Role_IsMandatory,
					R.Role_IsPrivate,
					R.Role_NoCopyNotes,
					R.Role_CanSetOnHold,
					R.Role_OpenAfterWFFinish,
					LU.FixedMapping_UserID AS UserID,
					LU.FixedMapping_UsergroupID,
					LU.FixedMapping_Usergroup_SelectedUserID,
					LU.email_when_others_finish,
					LU.abstain_from_participation,
					LU.abstain_set_dt,
					LU.abstain_set_on_stagecode,
					LU.abstain_set_on_iterationNo,
					LU.abstain_set_by_rolecode,
					LU.abstain_set_by_userid,
					SG.Name AS UserName,
					SG.first_Name AS UserFirstName,
					SG.last_Name AS UserLastName,
					SG.Email AS UserEmail,
					SG.phone AS UserPhone,
					SG.phone_area_code AS UserPhone_area_code,
					SG.company AS UserCompany,
					SR.StageRole_IsStageApprover,
					SR.StageRole_SortNo,
					SR.StageRole_FinishActions_IDs,
					SR.StageRole_FinishActions_Data,
					RESP.ResponsibilityCode,
					RESP.Responsibility_Description,
					RESP.Responsibility_DescriptionShort,
					RESP.Responsibility_SortNo,
					RESP.Responsibility_SortNo_alpha,
					RESP.Responsibility_DisplaySortNo,
					RESP.Responsibility_IsStageDecisionPoint,
					RESP.Responsibility_QTypeCode,
					RESP.Responsibility_QTypeSubCode,
					RESP.Responsibility_IsRequired,
					RESP.Responsibility_IsRequiredPositive,
					RESP.Responsibility_hasTextNote,
					RESP.Responsibility_AutoComment_Option2,
					RESP.Responsibility_AutoComment_Option3,
					RESP.Responsibility_AutoComment_Option4,
					RESP.previousStageSameRespCode,
					RESP.fyiRespCodeList,
					RESP.HiddenUntilOtherRespCodeAnsweredPositive,
					RESP.HiddenUntilOtherRespCodeAnsweredPositive2,
					RESP.HiddenUntilOtherRespCodeAnsweredNegative,
					RESP.HiddenUntilOtherRespCodeAnsweredNegative2,
					RESP.HiddenUntilOtherRespCodeAnsweredLastValue,
					RESP.HiddenUntilOtherRespCodeAnsweredLastValue2,
					RESP.HiddenIfOtherRespCodeAnsweredYes,
					RESP.HiddenIfOtherRespCodeAnsweredYes2,
					RESP.HiddenIfOtherRespCodeAnsweredNo,
					RESP.HiddenIfOtherRespCodeAnsweredNo2,
					RESP.CopyOtherRespCodeValue,
					RESP.Responsibility_forceTextNote,
					RESP.Responsibility_visibleForIteration,
					RESP.Responsibility_helpText,
					RESP.Responsibility_miscDetails1,
					RESP.Responsibility_miscDetails2,
					RESP.Responsibility_miscDetails3,
					RESP.Responsibility_miscDetails4,
					RESP.Responsibility_StandardFile_Number,
					RESP.Responsibility_StandardFile_UseProofingClient,
					RESP.Responsibility_StandardFile_DetailedFileInfo_Generate,
					RESP.Responsibility_StandardFile_DetailedFileInfo_Display,
					RESP.Responsibility_StandardFile_Display_SmartMedia_Metadata,
					RESP.Responsibility_StandardFile_ValidateUploadAgainstStandard, RESP.Responsibility_StandardFile_ValidateUploadAgainstStandard_PreventFinish,
					RESP.Responsibility_ActiveAfterFinish,
					RESP.Responsibility_ActiveUntilWorkflowFinish,
					RESP.Responsibility_hasGeneralComment,
					RESP.Responsibility_ReferencePanel,
					RESP.Responsibility_isSpecQuestion,
					RESP.Responsibility_AnswerNewLine,
					RESP.Responsibility_ShowInFixups,
					RESP.Responsibility_ParentQuestion_Reference,
					RESP.Responsibility_activeOnlyForAltWfsTypeID,
					RESP.Responsibility_OverrideButtonLabel,
					RESP.Responsibility_OverrideButtonWidth,
					RESP.Responsibility_OverrideButtonStyle,
					RESP.Responsibility_LogAnswer,
					RESP.Responsibility_HideNormalStageFinishButton,
					RESP.Responsibility_PackPanelElementID,
					V.ResponsibilityValue_Input,
					V.ResponsibilityValue_Input_extraData,
					V.ResponsibilityValue_Input_ntext,
					V.ResponsibilityValue_Input_TextNote,
					V.ResponsibilityValue_Input_UserID,
					V.ResponsibilityValue_Input_dt,
					V.ResponsibilityValue_Input_Override,
					V.ResponsibilityValue_Input_extraData_Override,
					V.ResponsibilityValue_Input_ntext_Override,
					V.ResponsibilityValue_Input_Override_TextNote,
					V.ResponsibilityValue_Input_Override_UserID,
					V.ResponsibilityValue_Input_Override_dt,
					V.ResponsibilityValue_Approval_Status,
					V.ResponsibilityValue_Approval_By,
					V.ResponsibilityValue_Approval_Date,
					V.ResponsibilityValue_Approval_Log,
					SG2.email AS ResponsibilityValue_Input_UserEmail,
					SG2.name AS ResponsibilityValue_Input_UserName,
					SG2.phone AS ResponsibilityValue_Input_UserPhone,
					SG2.phone_area_code AS ResponsibilityValue_Input_UserPhoneAreaCode,
					SG2.Company AS ResponsibilityValue_Input_UserCompany,
					SG_Override.first_name AS ResponsibilityValue_Input_Override_UserFirstName,
					SG_Override.last_name AS ResponsibilityValue_Input_Override_UserLastName,
					RST.RoleSection_DateIn,
					RST.RoleSection_DateOut,
					RST.RoleSection_In_UserID,
					RST.RoleSection_Out_UserID,
					RST.RST_record_dt,
					RST.RST_GroupPrioritizationNumber,
					RST.RST_IsOpen,
					RST.RST_opened,
					RST.RST_opened_dt,
					RST.RST_SpecialStatus,
					RST.RST_IsSkipping,
					RST.RST_ViewedMarkupFile,
					( 
						CASE
						WHEN (RST.RoleSection_DateOut IS NULL) THEN 0
						ELSE 1
						END
					)
					AS RoleSection_isFinished,
					QT.QTypeCode, QT.QType_Label, QT.QType_Help, QT.QType_wfBuilderVisible, QT.QType_Description, QT.QType_ValuesCount,
					QT.QType_Label1, QT.QType_Value1, QT.QType_Label2, QT.QType_Value2, QT.QType_Label3, QT.QType_Value3, QT.QType_Label4, QT.QType_Value4,
					QT.QType_Label5, QT.QType_Value5, QT.QType_useFieldLock, QT.QType_DefaultButtonLabel, QT.QType_DefaultButtonWidth, QT.QType_DefaultButtonStyle,
					QT_Custom.QTypeCustomID, QT_Custom.QType_LibraryID, QT_Custom.QType_Custom_Label, QT_Custom.QType_Custom_Help, QT_Custom.QType_Custom_wfBuilderVisible,
					QT_Custom.QType_Custom_Description, QT_Custom.QType_Custom_ValuesCount, QT_Custom.QType_Custom_Label1, QT_Custom.QType_Custom_Value1, QT_Custom.QType_Custom_SetOtherAnswer_SetValue1,
					QT_Custom.QType_Custom_Label2, QT_Custom.QType_Custom_Value2, QT_Custom.QType_Custom_SetOtherAnswer_SetValue2, QT_Custom.QType_Custom_Label3, QT_Custom.QType_Custom_Value3, QT_Custom.QType_Custom_SetOtherAnswer_SetValue3,
					QT_Custom.QType_Custom_Label4, QT_Custom.QType_Custom_Value4, QT_Custom.QType_Custom_SetOtherAnswer_SetValue4, QT_Custom.QType_Custom_Label5, QT_Custom.QType_Custom_Value5, QT_Custom.QType_Custom_SetOtherAnswer_SetValue5,
					QT_Custom.QType_Custom_Label6, QT_Custom.QType_Custom_Value6, QT_Custom.QType_Custom_SetOtherAnswer_SetValue6, QT_Custom.QType_Custom_Label7, QT_Custom.QType_Custom_Value7, QT_Custom.QType_Custom_SetOtherAnswer_SetValue7,
					QT_Custom.QType_Custom_Label8, QT_Custom.QType_Custom_Value8, QT_Custom.QType_Custom_SetOtherAnswer_SetValue8, QT_Custom.QType_Custom_Label9, QT_Custom.QType_Custom_Value9, QT_Custom.QType_Custom_SetOtherAnswer_SetValue9,
					QT_Custom.QType_Custom_Label10, QT_Custom.QType_Custom_Value10, QT_Custom.QType_Custom_SetOtherAnswer_SetValue10, QT_Custom.QType_Custom_Label11, QT_Custom.QType_Custom_Value11, QT_Custom.QType_Custom_SetOtherAnswer_SetValue11,
					QT_Custom.QType_Custom_Label12, QT_Custom.QType_Custom_Value12, QT_Custom.QType_Custom_SetOtherAnswer_SetValue12, QT_Custom.QType_Custom_Label13, QT_Custom.QType_Custom_Value13, QT_Custom.QType_Custom_SetOtherAnswer_SetValue13,
					QT_Custom.QType_Custom_Label14, QT_Custom.QType_Custom_Value14, QT_Custom.QType_Custom_SetOtherAnswer_SetValue14, QT_Custom.QType_Custom_Label15, QT_Custom.QType_Custom_Value15, QT_Custom.QType_Custom_SetOtherAnswer_SetValue15,
					UG.UsergroupDescription,
					SG_UgSelUser.Name AS UgSelUserName,
					SG_UgSelUser.first_Name AS UgSelUserFirstName,
					SG_UgSelUser.last_Name AS UgSelUserLastName,
					SG_UgSelUser.Email AS UgSelUserEmail,
					SG_UgSelUser.phone AS UgSelUserPhone,
					SG_UgSelUser.phone_area_code AS UgSelUserPhone_area_code,
					SG_UgSelUser.company AS UgSelUserCompany,
					COPY_VAL.ResponsibilityValue_Input AS CopyOtherRespCodeValue_Value,
					1 as cfqueryparamFixer
				FROM [1i00_Central]..WFS_Task AS T
				JOIN [1i00_Central]..WFS_WorkFlowType AS W
				ON T.WFS_WorkFlowTypeCode = W.WorkFlowTypeCode
				JOIN [1i00_Central]..WFS_WorkflowType_Stages AS S
				ON T.WFS_WorkFlowTypeCode = S.WorkFlowTypeCode 
				JOIN [1i00_Central]..WFS_WorkflowType_Stage_Role_m2m AS SR
				ON SR.WorkFlowTypeCode = S.WorkFlowTypeCode
				AND SR.StageCode = S.StageCode
				AND SR.StageRole_IsActive = 1
				JOIN [1i00_Central]..WFS_WorkFlowType_Roles AS R
				ON SR.WorkFlowTypeCode = R.WorkFlowTypeCode
				AND SR.RoleCode = R.RoleCode
				AND R.Role_IsActive = 1
				JOIN [1i00_Central]..WFS_Item_role2users_FixedMappings AS LU
				ON R.WorkFlowTypeCode =LU.WorkFlowTypeCode
				AND R.RoleCode =LU.RoleCode
				AND LU.LibraryID = #arguments.jwtData.sessions.LibraryID#
				AND LU.ItemSeqNo =T.ItemSeqNo
				LEFT JOIN [1i00_Central]..i00wf_Item AS ITEM
				ON ITEM.ItemSeqNo = T.ItemSeqNo
				AND ITEM.LibraryID = T.LibraryID
				JOIN [1i00_Central]..WFS_WorkFlowType_Stage_Role_Responsibilities AS RESP
				ON SR.WorkFlowTypeCode = RESP.WorkFlowTypeCode
				AND SR.StageCode = RESP.StageCode
				AND SR.RoleCode = RESP.RoleCode
				AND RESP.Responsibility_IsActive = 1
				AND 
				( RESP.Responsibility_activeOnlyForAltWfsTypeID = ''
					OR RESP.Responsibility_activeOnlyForAltWfsTypeID IS NULL
					OR 
					( 
						RESP.Responsibility_activeOnlyForAltWfsTypeID <> '' AND ITEM.Item_alternateWFS_typeID = RESP.Responsibility_activeOnlyForAltWfsTypeID
					)
				)
				LEFT JOIN [1i00_Central]..WFS_Item_Stages_Track AS ST
				ON T.LibraryID = ST.LibraryID
				AND T.ItemSeqNo = ST.ItemSeqNo
				AND S.WorkflowtypeCode = ST.WorkflowtypeCode
				AND S.StageCode = ST.StageCode
				LEFT JOIN [1i00_SmarterWare]..sg_users AS SG
				ON SG.UserID = LU.FixedMapping_UserID
				LEFT JOIN [1i00_Central]..i00use_LibUsergroups AS UG
				ON UG.UsergroupID = LU.FixedMapping_UsergroupID
				AND UG.LibraryID = LU.LibraryID
				LEFT JOIN [1i00_Smarterware]..sg_users AS SG_UgSelUser
				ON SG_UgSelUser.userid = LU.FixedMapping_Usergroup_SelectedUserID
				AND LU.FixedMapping_Usergroup_SelectedUserID IS NOT NULL
				AND LU.FixedMapping_Usergroup_SelectedUserID <> ''
				LEFT JOIN [1i00_Central]..WFS_Item_ResponsibilityValues AS V
				ON RESP.WorkFlowTypeCode = V.WorkFlowTypeCode
				AND RESP.StageCode = V.StageCode
				AND RESP.RoleCode = V.RoleCode
				AND RESP.ResponsibilityCode = V.ResponsibilityCode
				AND T.LibraryID = V.LibraryID
				AND T.ItemSeqNo = V.ItemSeqNo
				AND V.StageIterationNo = 1
				LEFT JOIN [1i00_SmarterWare]..sg_users AS SG2
				ON SG2.UserID = V.ResponsibilityValue_Input_UserID
				LEFT JOIN [1i00_SmarterWare]..sg_users AS SG_Override ON SG_Override.UserID = V.ResponsibilityValue_Input_Override_UserID
				LEFT JOIN [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track AS RST
				ON RST.WorkFlowTypeCode = SR.WorkFlowTypeCode
				AND RST.StageCode = SR.StageCode
				AND RST.RoleCode = SR.RoleCode
				AND T.LibraryID = RST.LibraryID
				AND T.ItemSeqNo = RST.ItemSeqNo
				AND RST.StageIterationNo = 1
				LEFT JOIN [1i00_Central]..WFS_QTYPES AS QT
				ON QT.QTypeCode = RESP.Responsibility_QTypeCode
				LEFT JOIN [1i00_Central]..WFS_QTypes_Custom AS QT_Custom
				ON QT_Custom.QTypeCode = RESP.Responsibility_QTypeCode
				AND QT_Custom.QTypeCustomID = RESP.Responsibility_miscDetails1
				LEFT JOIN [1i00_Central]..WFS_Item_ResponsibilityValues AS COPY_VAL
				ON COPY_VAL.ResponsibilityCode = RESP.CopyOtherRespCodeValue
				AND COPY_VAL.LibraryID = T.LibraryID
				AND COPY_VAL.ItemSeqNo = T.ItemSeqNo
				AND COPY_VAL.StageIterationNo = 1
				WHERE T.LibraryID = #arguments.jwtData.sessions.LibraryID#
				AND T.ItemSeqNo = #arguments.itemSeqNo#

			)
			Select 
				Format(RoleSection_DateIn,'yyyy-MM-dd') RoleSection_DateIn,
				Format(RoleSection_DateOut,'yyyy-MM-dd') RoleSection_DateOut,
				Role_Description,
				UserFirstName,
				UserLastName,
				UserCompany,
				UgSelUserPhone,
				WorkFlowTypeCode,
				stageCode,
				RoleCode,
				RESPONSIBILITY_ISSTAGEDECISIONPOINT,
				ROLE_OPENAFTERWFFINISH,
				STAGEROLE_ISSTAGEAPPROVER,
				StageRole_SortNo,
				RST_IsSkipping,
				StageRole_displayTheAbstainOption,
				StageRole_AllowFinishWhenOneRequiredRespDone,
				Stage_IsRequiringRoleSectionsPrioritization,
				RST_IsOpen,
				abstain_from_participation,
				Stage_finished,
				RoleSection_isFinished,
				StageRole_hasGeneralRoleComments,
				StageRole_MustViewMarkupFile,
				RST_ViewedMarkupFile,
				Role_CanSetOnHold,
				StageRole_HasReferencePanel,
				STAGEROLE_GROUPPRIORITIZATIONNUMBER,
				V.ITEMSEQNO,
				CTE.UsergroupDescription,	
				CTE.UgSelUserName,	
				CTE.UgSelUserFirstName,	
				CTE.UgSelUserLastName,	
				CTE.UgSelUserEmail,	
				CTE.UgSelUserPhone,	
				CTE.UgSelUserCompany

			from CTE
			CROSS APPLY
			(
				select * 
				from V_WF_GetWFItem where ItemSeqNo = #arguments.itemSeqNo#
			) V

			GROUP BY 
				Format(RoleSection_DateIn,'yyyy-MM-dd'),
				Format(RoleSection_DateOut,'yyyy-MM-dd'),
				Role_Description,
				UserFirstName,
				UserLastName,
				UserCompany,
				UgSelUserPhone,
				stageCode,
				RoleCode,
				RESPONSIBILITY_ISSTAGEDECISIONPOINT,
				ROLE_OPENAFTERWFFINISH,
				STAGEROLE_ISSTAGEAPPROVER,
				StageRole_SortNo,
				RST_IsSkipping,
				StageRole_displayTheAbstainOption,
				StageRole_AllowFinishWhenOneRequiredRespDone,
				Stage_IsRequiringRoleSectionsPrioritization,
				RST_IsOpen,
				abstain_from_participation,
				Stage_finished,
				RoleSection_isFinished,
				StageRole_hasGeneralRoleComments,
				StageRole_MustViewMarkupFile,
				RST_ViewedMarkupFile,
				Role_CanSetOnHold,
				StageRole_HasReferencePanel,
				STAGEROLE_GROUPPRIORITIZATIONNUMBER,
				V.ITEMSEQNO,
				WorkFlowTypeCode,
				CTE.UsergroupDescription,	
				CTE.UgSelUserName,	
				CTE.UgSelUserFirstName,	
				CTE.UgSelUserLastName,	
				CTE.UgSelUserEmail,	
				CTE.UgSelUserPhone,	
				CTE.UgSelUserCompany				
			ORDER BY StageCode, StageRole_GroupPrioritizationNumber
		
		</cfquery>

		<cfreturn rsSubStageData>
		
	</cffunction>

	<cffunction  name="getQuestions" access="public" returntype="any">
		<cfargument  name="itemSeqNo" type="numeric" required="true">
		<cfargument  name="currentStageCode" type="string" required="true">
		<cfargument  name="jwtData" type="struct" required="true">
		<cfargument  name="run_for_IsStageDecisionPoint" type="numeric" required="false" default="0">


        <cfquery name="rsSubStageData" datasource="#jwtData.SESSIONS.library_context.LibraryODBCsource#">
            SELECT T.libraryid,
            T.itemseqno,
            T.wfs_workflowtypecode,
            T.wfs_stagecode,
            T.wfs_designforprepress_filename_saved,
            T.wfs_designforprepress_filename_original,
            T.wfs_designforprepress_pdf_filename_saved,
            T.wfs_designforprepress_pdf_filename_original,
            T.wfs_artwork_id,
            T.wfs_rolefinish_emailstageapprover,
            ITEM.item_standardclassifier_barcode,
            ITEM.item_standardclassifier_tun,
            ITEM.item_standardclassifier_barcodetype,
            ITEM.item_standardclassifier_productcode,
            ITEM.item_standardclassifier_artworknumber,
            ITEM.item_standardclassifier_dieline,
            ITEM.item_standardclassifier_filesupplierref,
            ITEM.item_standardclassifier_countryoforigin,
            ITEM.item_standardclassifier_gpcbrickcode,
            ITEM.item_standardclassifier_workflowsubtype,
            ITEM.item_standardclassifier_material_bom,
            ITEM.item_standardclassifier_finishedartprovider,
            ITEM.item_standardclassifier_designer,
            ITEM.item_standardclassifier_prepress,
            ITEM.item_standardclassifier_printer,
            ITEM.item_standardclassifier_gln,
            ITEM.item_standardclassifier_smartmedia_status,
            ITEM.item_standardclassifier_smartmedia_filenamemetadata,
            ITEM.item_standardclassifier_smartmedia_availabilitydate_start,
            ITEM.item_standardclassifier_smartmedia_availabilitydate_end,
            ITEM.item_standardclassifier_smartmedia_promotiondate_start,
            ITEM.item_standardclassifier_smartmedia_promotiondate_end,
            ITEM.item_itemcode,
            ITEM.item_wf_parent_seqno,
            ITEM.item_alternatewfs_typeid,
            W.workflowtype_description,
            W.workflowtype_respcodeforfinartwffoldercode,
            W.workflowtype_createquestionforfinartwffoldercode,
            W.workflowtype_itemcodeforfinartwffoldercode,
            W.workflowtype_wfsspecifictype,
            W.workflowtype_altwfs_typeinsteadoffirstfile,
            W.workflowtype_showotherroleslink,
            W.workflowtype_showcompanywithuser,
            W.creatediffwftypeonfinish,
            W.workflowtype_usefileuploadoptionalpreview,
            W.workflowtype_stageapprovewhenonerolefinish,
            W.workflowtype_stageapprovewhentworolefinish,
            W.workflowtype_stageapprovewhenthreerolefinish,
            W.workflowtype_altwfs_canstageapprovealtmethod,
            W.workflowtype_altwfs_usequotegroup,
            W.workflowtype_usefdf,
            W.workflowtype_useremotedirector,
            W.workflowtype_usevproof,
            W.workflowtype_damonstagefinish,
            W.workflowtype_damonfinish,
            W.workflowtype_damonfinish_makeoldmatchingitemcode,
            W.workflowtype_damonfinish_requirespendinguploadapproval,
            W.workflowtype_resetabstaineachstage,
            W.workflowtype_forceemaildamuploadonfinish,
            W.workflowtype_generalworkflowcomments,
            W.workflowtype_usestageappractioncomments,
            ''                                 AS
            WorkFlowType_StandardClassifier_Barcode_SpecificValidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_BarcodeType_SpecificValidation,
            W.workflowtype_standardclassifier_productcode_specificvalidation,
            W.workflowtype_standardclassifier_artworknumber_specificvalidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_Dieline_SpecificValidation,
            W.workflowtype_standardclassifier_filesupplierref_specificvalidation,
            W.workflowtype_standardclassifier_gpcbrickcode_specificvalidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_WorkflowSubType_SpecificValidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_Material_BOM_SpecificValidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_FinishedArtProvider_SpecificValidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_Designer_SpecificValidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_PrePress_SpecificValidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_Printer_SpecificValidation,
            W.workflowtype_standardclassifier_gln_specificvalidation,
            ''                                 AS
            WorkFlowType_StandardClassifier_SmartMedia_Status_SpecificValidation,
            ''                                 AS
			WorkFlowType_StandardClassifier_SmartMedia_FilenameMetadata_SpecificValidation,
			''                                 AS
			WorkFlowType_StandardClassifier_SmartMedia_AvailabilityDate_Start_SpecificValidation
				,
			''                                 AS
			WorkFlowType_StandardClassifier_SmartMedia_AvailabilityDate_End_SpecificValidation
				,
			''                                 AS
			WorkFlowType_StandardClassifier_SmartMedia_PromotionDate_Start_SpecificValidation
				,
			''                                 AS
			WorkFlowType_StandardClassifier_SmartMedia_PromotionDate_End_SpecificValidation,
			SR.workflowtypecode,
			SR.stagecode,
			SR.rolecode,
			SR.stagerole_hasgeneralrolecomments,
			SR.stagerole_displaytheabstainoption,
			SR.stagerole_emailmefinishsummary,
			SR.stagerole_dontopenemailuserjustfinished,
			SR.stagerole_onlyinvolvewhenpreviousdone,
			SR.stagerole_onlyexposewhenpreviousdone,
			SR.stagerole_groupprioritizationnumber,
			SR.stagerole_emailperiodstartoncecomplete,
			SR.stagerole_allowfinishwhenonerequiredrespdone,
			SR.stagerole_allowfinishwhenrespcodeyes,
			SR.stagerole_emailactionapproval,
			SR.stagerole_hasreferencepanel,
			SR.stagerole_mustviewmarkupfile,
			SR.stagerole_asknewjobonfinish,
			SR.stagerole_email_sendto_rolecodes_rolefinish,
			SR.stagerole_preventunfinishinsummary,
			S.stage_description,
			S.stage_definition,
			S.stage_isfinalapprovalpoint,
			S.stage_seqno,
			S.stage_displayseqno,
			S.stage_ismandatory,
			S.stage_isauxiliary,
			S.stage_isdesignart,
			S.stage_istechnicalproof,
			S.stage_isfinalcorrectedproof,
			S.stage_isprivate,
			S.stage_isrequiringrolesectionsprioritization,
			S.stage_groupnumberatwhichtonotifyobservers,
			S.stage_hasquoterequests,
			S.stage_email_requestapproval_includereferencepanel,
			S.stage_email_requestapproval_includereferencepanel_iteration,
			S.stage_email_requestapproval_includecorrections,
			S.stage_email_requestapproval_includecorrections_iteration,
			S.stage_email_approved_includereferencepanel,
			S.stage_email_approved_includecorrections,
			S.stage_email_approved_sendtorolecodes,
			Isnull(ST.stage_status, 0)         AS Stage_Status,
			Isnull(ST.stage_started, 0)        AS Stage_Started,
			ST.stage_started_dt,
			ST.stage_finished,
			ST.stage_finished_dt,
			Isnull(ST.stage_was_skipped, 0)    AS Stage_was_skipped,
			ST.stage_was_skipped_dt,
			ST.stage_was_skipped_by_userid,
			R.role_description,
			R.role_isworkflowmanager,
			R.role_isinitiator,
			R.role_isdesignprovider,
			R.role_isprintingprovider,
			R.role_isobserver,
			R.role_ismandatory,
			R.role_isprivate,
			R.role_nocopynotes,
			R.role_cansetonhold,
			R.role_openafterwffinish,
			LU.fixedmapping_userid             AS UserID,
			LU.fixedmapping_usergroupid,
			LU.fixedmapping_usergroup_selecteduserid,
			LU.email_when_others_finish,
			LU.abstain_from_participation,
			LU.abstain_set_dt,
			LU.abstain_set_on_stagecode,
			LU.abstain_set_on_iterationno,
			LU.abstain_set_by_rolecode,
			LU.abstain_set_by_userid,
			SG.NAME                            AS UserName,
			SG.first_name                      AS UserFirstName,
			SG.last_name                       AS UserLastName,
			SG.email                           AS UserEmail,
			SG.phone                           AS UserPhone,
			SG.phone_area_code                 AS UserPhone_area_code,
			SG.company                         AS UserCompany,
			SR.stagerole_isstageapprover,
			SR.stagerole_sortno,
			SR.stagerole_finishactions_ids,
			SR.stagerole_finishactions_data,
			RESP.responsibilitycode,
			RESP.responsibility_description,
			RESP.responsibility_descriptionshort,
			RESP.responsibility_sortno,
			RESP.responsibility_sortno_alpha,
			RESP.responsibility_displaysortno,
			RESP.responsibility_isstagedecisionpoint,
			RESP.responsibility_qtypecode,
			RESP.responsibility_qtypesubcode,
			RESP.responsibility_isrequired,
			RESP.responsibility_isrequiredpositive,
			RESP.responsibility_hastextnote,
			RESP.responsibility_autocomment_option2,
			RESP.responsibility_autocomment_option3,
			RESP.responsibility_autocomment_option4,
			RESP.previousstagesamerespcode,
			RESP.fyirespcodelist,
			V.stageiterationno,
			RESP.hiddenuntilotherrespcodeansweredpositive,
			RESP.hiddenuntilotherrespcodeansweredpositive2,
			RESP.hiddenuntilotherrespcodeanswerednegative,
			RESP.hiddenuntilotherrespcodeanswerednegative2,
			RESP.hiddenuntilotherrespcodeansweredlastvalue,
			RESP.hiddenuntilotherrespcodeansweredlastvalue2,
			RESP.hiddenifotherrespcodeansweredyes,
			RESP.hiddenifotherrespcodeansweredyes2,
			RESP.hiddenifotherrespcodeansweredno,
			RESP.hiddenifotherrespcodeansweredno2,
			RESP.copyotherrespcodevalue,
			RESP.responsibility_forcetextnote,
			RESP.responsibility_visibleforiteration,
			RESP.responsibility_helptext,
			RESP.responsibility_miscdetails1,
			RESP.responsibility_miscdetails2,
			RESP.responsibility_miscdetails3,
			RESP.responsibility_miscdetails4,
			RESP.responsibility_standardfile_number,
			RESP.responsibility_standardfile_useproofingclient,
			RESP.responsibility_standardfile_detailedfileinfo_generate,
			RESP.responsibility_standardfile_detailedfileinfo_display,
			RESP.responsibility_standardfile_display_smartmedia_metadata,
			RESP.responsibility_standardfile_validateuploadagainststandard,
			RESP.responsibility_standardfile_validateuploadagainststandard_preventfinish,
			RESP.responsibility_activeafterfinish,
			RESP.responsibility_activeuntilworkflowfinish,
			RESP.responsibility_hasgeneralcomment,
			RESP.responsibility_referencepanel,
			RESP.responsibility_isspecquestion,
			RESP.responsibility_answernewline,
			RESP.responsibility_showinfixups,
			RESP.responsibility_parentquestion_reference,
			RESP.responsibility_activeonlyforaltwfstypeid,
			RESP.responsibility_overridebuttonlabel,
			RESP.responsibility_overridebuttonwidth,
			RESP.responsibility_overridebuttonstyle,
			RESP.responsibility_loganswer,
			RESP.responsibility_hidenormalstagefinishbutton,
			RESP.responsibility_packpanelelementid,
			V.responsibilityvalue_input,
			V.responsibilityvalue_input_extradata,
			V.responsibilityvalue_input_ntext,
			V.responsibilityvalue_input_textnote,
			V.responsibilityvalue_input_userid,
			V.responsibilityvalue_input_dt,
			V.responsibilityvalue_input_override,
			V.responsibilityvalue_input_extradata_override,
			V.responsibilityvalue_input_ntext_override,
			V.responsibilityvalue_input_override_textnote,
			V.responsibilityvalue_input_override_userid,
			V.responsibilityvalue_input_override_dt,
			V.responsibilityvalue_approval_status,
			V.responsibilityvalue_approval_by,
			V.responsibilityvalue_approval_date,
			V.responsibilityvalue_approval_log,
			SG2.email                          AS ResponsibilityValue_Input_UserEmail,
			SG2.NAME                           AS ResponsibilityValue_Input_UserName,
			SG2.phone                          AS ResponsibilityValue_Input_UserPhone,
			SG2.phone_area_code                AS
				ResponsibilityValue_Input_UserPhoneAreaCode,
			SG2.company                        AS ResponsibilityValue_Input_UserCompany,
			SG_Override.first_name             AS
				ResponsibilityValue_Input_Override_UserFirstName,
			SG_Override.last_name              AS
				ResponsibilityValue_Input_Override_UserLastName,
			RST.rolesection_datein,
			RST.rolesection_dateout,
			RST.rolesection_in_userid,
			RST.rolesection_out_userid,
			RST.rst_record_dt,
			RST.rst_groupprioritizationnumber,
			RST.rst_isopen,
			RST.rst_opened,
			RST.rst_opened_dt,
			RST.rst_specialstatus,
			RST.rst_isskipping,
			RST.rst_viewedmarkupfile,
			( CASE
				WHEN ( RST.rolesection_dateout IS NULL ) THEN 0
				ELSE 1
			END )                            AS RoleSection_isFinished,
			QT.qtypecode,
			SR.stagerole_groupprioritizationnumber,
			QT.qtype_label,
			QT.qtype_help,
			QT.qtype_wfbuildervisible,
			QT.qtype_description,
			QT.qtype_valuescount,
			QT.qtype_label1,
			QT.qtype_value1,
			QT.qtype_label2,
			QT.qtype_value2,
			QT.qtype_label3,
			QT.qtype_value3,
			QT.qtype_label4,
			QT.qtype_value4,
			QT.qtype_label5,
			QT.qtype_value5,
			QT.qtype_usefieldlock,
			QT.qtype_defaultbuttonlabel,
			QT.qtype_defaultbuttonwidth,
			QT.qtype_defaultbuttonstyle,
			QT_Custom.qtypecustomid,
			QT_Custom.qtype_libraryid,
			QT_Custom.qtypecode,
			QT_Custom.qtype_custom_label,
			QT_Custom.qtype_custom_help,
			QT_Custom.qtype_custom_wfbuildervisible,
			QT_Custom.qtype_custom_description,
			QT_Custom.qtype_custom_valuescount,
			QT_Custom.qtype_custom_label1,
			QT_Custom.qtype_custom_value1,
			QT_Custom.qtype_custom_setotheranswer_setvalue1,
			QT_Custom.qtype_custom_label2,
			QT_Custom.qtype_custom_value2,
			QT_Custom.qtype_custom_setotheranswer_setvalue2,
			QT_Custom.qtype_custom_label3,
			QT_Custom.qtype_custom_value3,
			QT_Custom.qtype_custom_setotheranswer_setvalue3,
			QT_Custom.qtype_custom_label4,
			QT_Custom.qtype_custom_value4,
			QT_Custom.qtype_custom_setotheranswer_setvalue4,
			QT_Custom.qtype_custom_label5,
			QT_Custom.qtype_custom_value5,
			QT_Custom.qtype_custom_setotheranswer_setvalue5,
			QT_Custom.qtype_custom_label6,
			QT_Custom.qtype_custom_value6,
			QT_Custom.qtype_custom_setotheranswer_setvalue6,
			QT_Custom.qtype_custom_label7,
			QT_Custom.qtype_custom_value7,
			QT_Custom.qtype_custom_setotheranswer_setvalue7,
			QT_Custom.qtype_custom_label8,
			QT_Custom.qtype_custom_value8,
			QT_Custom.qtype_custom_setotheranswer_setvalue8,
			QT_Custom.qtype_custom_label9,
			QT_Custom.qtype_custom_value9,
			QT_Custom.qtype_custom_setotheranswer_setvalue9,
			QT_Custom.qtype_custom_label10,
			QT_Custom.qtype_custom_value10,
			QT_Custom.qtype_custom_setotheranswer_setvalue10,
			QT_Custom.qtype_custom_label11,
			QT_Custom.qtype_custom_value11,
			QT_Custom.qtype_custom_setotheranswer_setvalue11,
			QT_Custom.qtype_custom_label12,
			QT_Custom.qtype_custom_value12,
			QT_Custom.qtype_custom_setotheranswer_setvalue12,
			QT_Custom.qtype_custom_label13,
			QT_Custom.qtype_custom_value13,
			QT_Custom.qtype_custom_setotheranswer_setvalue13,
			QT_Custom.qtype_custom_label14,
			QT_Custom.qtype_custom_value14,
			QT_Custom.qtype_custom_setotheranswer_setvalue14,
			QT_Custom.qtype_custom_label15,
			QT_Custom.qtype_custom_value15,
			QT_Custom.qtype_custom_setotheranswer_setvalue15,
			UG.usergroupdescription,
			SG_UgSelUser.NAME                  AS UgSelUserName,
			SG_UgSelUser.first_name            AS UgSelUserFirstName,
			SG_UgSelUser.last_name             AS UgSelUserLastName,
			SG_UgSelUser.email                 AS UgSelUserEmail,
			SG_UgSelUser.phone                 AS UgSelUserPhone,
			SG_UgSelUser.phone_area_code       AS UgSelUserPhone_area_code,
			SG_UgSelUser.company               AS UgSelUserCompany,
			COPY_VAL.responsibilityvalue_input AS CopyOtherRespCodeValue_Value,
			1                                  AS cfqueryparamFixer
			FROM   [1i00_Central]..wfs_task AS T
				JOIN [1i00_Central]..wfs_workflowtype AS W
					ON T.wfs_workflowtypecode = W.workflowtypecode
				JOIN [1i00_Central]..wfs_workflowtype_stages AS S
					ON T.wfs_workflowtypecode = S.workflowtypecode
						AND S.stagecode = '#arguments.currentStageCode#'
				JOIN [1i00_Central]..wfs_workflowtype_stage_role_m2m AS SR
					ON SR.workflowtypecode = S.workflowtypecode
						AND SR.stagecode = S.stagecode
						AND SR.stagerole_isactive = 1
				JOIN [1i00_Central]..wfs_workflowtype_roles AS R
					ON SR.workflowtypecode = R.workflowtypecode
						AND SR.rolecode = R.rolecode
						AND R.role_isactive = 1
				JOIN [1i00_Central]..wfs_item_role2users_fixedmappings AS LU
					ON R.workflowtypecode = LU.workflowtypecode
						AND R.rolecode = LU.rolecode
						AND LU.libraryid = '#arguments.jwtData.SESSIONS.LibraryID#'
						AND LU.itemseqno = T.itemseqno
				LEFT JOIN [1i00_Central]..i00wf_item AS ITEM
						ON ITEM.itemseqno = T.itemseqno
							AND ITEM.libraryid = T.libraryid
				JOIN [1i00_Central]..wfs_workflowtype_stage_role_responsibilities AS RESP
					ON SR.workflowtypecode = RESP.workflowtypecode
						AND SR.stagecode = RESP.stagecode
						AND SR.rolecode = RESP.rolecode
						AND RESP.responsibility_isactive = 1
						AND ( RESP.responsibility_activeonlyforaltwfstypeid = ''
							OR RESP.responsibility_activeonlyforaltwfstypeid IS NULL
							OR ( RESP.responsibility_activeonlyforaltwfstypeid <> ''
									AND ITEM.item_alternatewfs_typeid =
										RESP.responsibility_activeonlyforaltwfstypeid ) )
				LEFT JOIN [1i00_Central]..wfs_item_stages_track AS ST
						ON T.libraryid = ST.libraryid
							AND T.itemseqno = ST.itemseqno
							AND S.workflowtypecode = ST.workflowtypecode
							AND S.stagecode = ST.stagecode
				LEFT JOIN [1i00_SmarterWare]..sg_users AS SG
						ON SG.userid = LU.fixedmapping_userid
				LEFT JOIN [1i00_Central]..i00use_libusergroups AS UG
						ON UG.usergroupid = LU.fixedmapping_usergroupid
							AND UG.libraryid = LU.libraryid
				LEFT JOIN [1i00_Smarterware]..sg_users AS SG_UgSelUser
						ON SG_UgSelUser.userid = LU.fixedmapping_usergroup_selecteduserid
							AND LU.fixedmapping_usergroup_selecteduserid IS NOT NULL
							AND LU.fixedmapping_usergroup_selecteduserid <> ''
				LEFT JOIN [1i00_Central]..wfs_item_responsibilityvalues AS V
						ON RESP.workflowtypecode = V.workflowtypecode
							AND RESP.stagecode = V.stagecode
							AND RESP.rolecode = V.rolecode
							AND RESP.responsibilitycode = V.responsibilitycode
							AND T.libraryid = V.libraryid
							AND T.itemseqno = V.itemseqno
							AND V.stageiterationno = 1
				LEFT JOIN [1i00_SmarterWare]..sg_users AS SG2
						ON SG2.userid = V.responsibilityvalue_input_userid
				LEFT JOIN [1i00_SmarterWare]..sg_users AS SG_Override
						ON SG_Override.userid =
							V.responsibilityvalue_input_override_userid
				LEFT JOIN [1i00_Central]..wfs_item_stage_iteration_rolesections_track AS
							RST
						ON RST.workflowtypecode = SR.workflowtypecode
							AND RST.stagecode = SR.stagecode
							AND RST.rolecode = SR.rolecode
							AND T.libraryid = RST.libraryid
							AND T.itemseqno = RST.itemseqno
							AND RST.stageiterationno = 1
				LEFT JOIN [1i00_Central]..wfs_qtypes AS QT
						ON QT.qtypecode = RESP.responsibility_qtypecode
				LEFT JOIN [1i00_Central]..wfs_qtypes_custom AS QT_Custom
						ON QT_Custom.qtypecode = RESP.responsibility_qtypecode
							AND QT_Custom.qtypecustomid = RESP.responsibility_miscdetails1
				LEFT JOIN [1i00_Central]..wfs_item_responsibilityvalues AS COPY_VAL
						ON COPY_VAL.responsibilitycode = RESP.copyotherrespcodevalue
							AND COPY_VAL.libraryid = T.libraryid
							AND COPY_VAL.itemseqno = T.itemseqno
							AND COPY_VAL.stageiterationno = 1
				WHERE  T.libraryid = '#arguments.jwtData.SESSIONS.LibraryID#'
					AND T.itemseqno = '#arguments.itemSeqNo#'
					

				ORDER  BY SR.stagerole_sortno,
					SR.rolecode,
					RESP.responsibility_sortno,
					RESP.responsibility_sortno_alpha,
					RESP.responsibilitycode 
                </cfquery>
                <cfquery name="getWFitem" datasource="#jwtData.SESSIONS.library_context.LibraryODBCsource#">
                	SELECT 
                    V.LibraryID,W.WorkflowType_UseStageApprActionComments, V.ItemSeqNo, V.Item_WFS, #arguments.currentStageCode# AS StageCode, V.Item_Status, V.SubmitterUserid, V.ManagerUserid, V.UploaderUserid, V.Item_dt_submitted, V.ApproverUserid, V.Item_Resource_RUID, V.Item_dt_released, V.Item_dt_suspended,
                    V.Item_dt_approved, V.Item_dt_rejected, V.Item_dt_cancelled, V.Item_dt_cancelled_by_userid, V.Item_is_archived, V.Item_is_deleted, V.Item_dt_archived, V.Item_dt_deleted, V.Item_archived_by_userid, V.Item_deleted_by_userid,
                    V.Item_DecisionNote, V.Item_prev_ItemSeqNo, V.Item_next_ItemSeqNo, V.Item_MarkupLastChangeNo, V.Item_MarkupLastGeneratedChangeNo, V.Item_MarkupIsActive, V.Item_MarkupActive_Type, V.Item_MarkupActive_OrigFile_dt_stamp,
                    V.Item_MarkupBy_dt_started, V.dt_now, V.Item_MarkupBy_warnings, V.Item_MarkupBy_UserID, V.Item_MarkupBy_cfid, V.Item_MarkupBy_cftoken, V.Item_MarkupBy_usermachine, V.Item_MarkupBy_remote_addr, V.Item_MarkupBy_Simultaneous,
                    V.Item_MarkupBy_SessionID, V.Item_Markup_WF_Current_RTImarkupID, V.Item_Markup_PROOF_Current_RTImarkupID,
                    FORMAT(V.Item_wf_StartDate, 'dd MMM yyyy') Item_wf_StartDate, FORMAT(V.Item_wf_IntermediateDate, 'dd MMM yyyy') Item_wf_IntermediateDate, FORMAT(V.Item_wf_DueDate, 'dd MMM yyyy') Item_wf_DueDate, V.Item_wf_Objective, V.Item_wf_TextNote, V.Item_wf_Priority, V.Item_wf_LockedNoComments, V.Item_wf_SignoffRequested,
                    V.Item_wf_client_reference, V.Item_wf_Final_Approver_Comments, V.Item_wf_Final_Approver_Last_Viewed, V.Item_FinishedArt_RUID, V.Item_CCAID, V.Item_finished_file_resource_type,
                    V.Item_ItemCode, V.Item_Version, V.Item_ClientCodeA, V.Item_ClientCodeB, V.Item_ClientCodeC, V.WorkFlowType_Description, V.WorkFlowType_FinalArt_ApprovalUsergroupID, V.WorkFlowType_WFSSpecificType, V.WorkFlowType_AlternateWFSUsesProof,
                    V.WorkFlowType_AltWFS_RoleLabel, V.WorkFlowType_AltWFS_CreatorIsManager, V.WorkFlowType_UseRtiAnnotations, V.WorkFlowType_UseFDF, V.WorkFlowType_UseVProof, V.WorkFlowType_ShowOtherRolesLink, V.WorkFlowType_UseFileUploadOptionalPreview,
                    V.WorkFlowType_AltWFS_UseQuoteGroup, V.WorkFlowType_AltWFS_QuoteGroupLabel, V.WorkFlowType_AltWFS_UploadBrief, V.WorkFlowType_AltWFS_TypeInsteadOfFirstFile, V.WorkFlowType_AltWFS_SepGroupPerRole,
                    V.WorkFlowType_StageApproveWhenOneRoleFinish, V.WorkFlowType_StageApproveWhenTwoRoleFinish, V.WorkFlowType_StageApproveWhenThreeRoleFinish, V.WorkFlowType_DueDateLabel, V.WorkFlowType_ApprovalRoleLabel, V.WorkFlowType_IsActive, V.WorkFlowType_UsePostActionNotification,
                    V.WorkflowType_ClientCodeALabel, V.WorkflowType_ClientCodeBLabel, V.WorkflowType_ClientCodeCLabel,
                    V.WorkflowType_ClientCodeACharType, V.WorkflowType_ClientCodeALengthMin, V.WorkflowType_ClientCodeALengthMax, V.WorkflowType_ClientCodeBCharType,
                    V.WorkflowType_ClientCodeBLengthMin, V.WorkflowType_ClientCodeBLengthMax, V.WorkflowType_ClientCodeCCharType,
                    V.WorkflowType_ClientCodeCLengthMin, V.WorkflowType_ClientCodeCLengthMax, V.WFS_Designer_Company, V.WFS_Designer_ContactPerson, V.WFS_Printer_Company, V.WFS_Printer_ContactPerson,
                    V.WFS_Artwork_hasBeenSubmtted, V.WFS_Artwork_hasBeenSubmtted_dt, V.WFS_Artwork_hasBeenSubmtted_userid, V.WFS_Artwork_ID, V.WFS_Proof_hasBeenSubmtted, V.WFS_Proof_hasBeenSubmtted_dt, V.WFS_Proof_hasBeenSubmtted_userid,
                    V.WFS_Proofing_ID, V.WFS_WorkFlowTypeCode, V.WFS_DesignForPrepress_Filename_Saved, V.WFS_DesignForPrepress_Filename_Original, V.WFS_DesignForPrepress_PDF_Filename_Saved, V.WFS_DesignForPrepress_PDF_Filename_Original,
                    V.WFS_QuoteGroup, V.WFS_UploadBrief_Filename_Saved, V.WFS_UploadBrief_Filename_Original, V.WFS_RoleFinish_EmailStageApprover, V.Proofing_OrigFileName, V.Proofing_WorkFileName, V.Proofing_UploadRef, V.Proofing_Status,
                    V.ApproverName, V.ApproverEmail, V.ApproverPhone, V.SubmitterName, V.SubmitterEmail, V.SubmitterPhone, V.Submitter_CCAID,
                    V.ManagerName, V.ManagerEmail, V.ManagerPhone, V.ManagerCompany, V.ManagerPhoneAreaCode, V.ManageraddressFloorLevel, V.ManagerAddress, V.ManagerState, V.ManagerPostcode, V.Manager_CCAID,
                    V.OriginalSubmitterName, V.OriginalSubmitterEmail, V.OriginalSubmitterPhone, V.UploaderName, V.UploaderEmail, V.UploaderPhone,
                    V.RDescription, V.RCodeInLibrary, V.priorRevisionOrder, V.priorRevisionSeriesID, V.RDeleted, V.Bin3_Status, V.Bin3_OrigFileName,
                    V.Item_fastReview_resourceTypeID, V.Item_fastReview_usergroupID, V.Item_alternateWFS_typeID, V.Item_DAM_Parent_RUID,
                    V.RTcodename, V.UsergroupDescription, V.alternateWFSType_label, V.LibSpecific_FinalArt_ApprovalUsergroupID,
                    W.WorkFlowType_UseRemoteDirector
                    FROM V_WF_GetWFItem V
                    LEFT OUTER JOIN [1i00_Central].dbo.WFS_WorkFlowType W ON V.WFS_WorkFlowTypeCode = W.WorkFlowTypeCode
                    WHERE LibraryID = '#arguments.jwtData.SESSIONS.LibraryID#'
                    AND ItemSeqNo = '#arguments.itemSeqNo#'
                </cfquery>  
                <!--- Initialize an empty array to store JSON objects --->
				<cfset jsonArray = []>
			<cfif StructKeyExists(request, 'getUserProfile') EQ false >
				<cfquery name="request.getUserProfile" datasource="#jwtData.SESSIONS.library_context.LibraryODBCsource#">
					SELECT	CUP.UserID,
							CUP.UserMaxEmailKB,
							CUP.UserDownloadMethod,
							CUP.UserUploadDeferingOption,
							CUP.UserUploadMethod,
							CUP.UserSettingOS,
							CUP.UserSettingHDD,
							CUP.LargeFileDownloadMethod,
							CUP.ReceiveWorkflowEmails_OffDate,
							CUP.UserSetting_HTML_Emails,
							CUP.UserPostLoginPage,
							CUP.DamSearch_ResultsDetailsDisplay,
							CUP.UserSpecific_WFList_GroupBy,
							CUP.UserSpecific_WFList_GroupByOrder,
							CUP.UserProofingClientType,
							[1i00_SmarterWare]..sg_users.LoginName,
							[1i00_SmarterWare]..sg_users.name,
							[1i00_SmarterWare]..sg_users.first_name,
							[1i00_SmarterWare]..sg_users.last_name,
							[1i00_SmarterWare]..sg_users.email,
							[1i00_SmarterWare]..sg_users.title,
							[1i00_SmarterWare]..sg_users.company,
							[1i00_SmarterWare]..sg_users.department,
							[1i00_SmarterWare]..sg_users.addressFloorLevel,
							[1i00_SmarterWare]..sg_users.address,
							[1i00_SmarterWare]..sg_users.suburb,
							[1i00_SmarterWare]..sg_users.state,
							[1i00_SmarterWare]..sg_users.country,
							[1i00_SmarterWare]..sg_users.postcode,
							[1i00_SmarterWare]..sg_users.phone_area_code,
							[1i00_SmarterWare]..sg_users.phone,
							[1i00_SmarterWare]..sg_users.mobile,
							[1i00_SmarterWare]..sg_users.LanguageCode,
							[1i00_SmarterWare]..sg_users.CountryCode,
							[1i00_SmarterWare]..sg_users.password_mustChange,
							[1i00_SmarterWare]..sg_users.ID,
							<!--- [1i00_SmarterWare]..sg_users.StandardCompany_CompanyID,
							[1i00_SmarterWare]..sg_users.StandardCompany_SuburbID, --->
							[1i00_SmarterWare]..sg_users.preapproved_status,
							[1i00_SmarterWare]..sg_users.A3
							<!--- BH 31/1/2017 - RW requested this be deleted after requesting it be added a year ago -  , [1i00_SmarterWare]..sg_users.InternalExternalUser --->

					FROM	[1i00_Central]..i00use_Cust1i00userprofile	AS CUP
					JOIN	[1i00_SmarterWare]..sg_users
						ON	CUP.UserID = [1i00_SmarterWare]..sg_users.UserID

					WHERE	CUP.UserID = <cfqueryparam value="#jwtData.sessions.userid#" cfsqltype="CF_SQL_VARCHAR">
				</cfquery>
			</cfif>

		<cfquery  datasource="#jwtData.SESSIONS.library_context.LibraryODBCsource#" name="request.THIS_qStages">
			SELECT
				T.WFS_WorkFlowTypeCode,
				T.WFS_StageCode,
				W.WorkflowtypeCode,
				W.Workflowtype_Description,
				W.WorkFlowType_UsageNote,
				S.StageCode,
				S.Stage_Description,
				S.Stage_Definition,
				S.Stage_SeqNo,
				S.Stage_DisplaySeqNo,
				S.Stage_IsAuxiliary,
				S.Stage_IsDesignArt,
				S.Stage_IsTechnicalProof,
				S.Stage_IsFinalCorrectedProof,
				S.Stage_IsRequiringRoleSectionsPrioritization,
				S.Stage_GroupNumberAtWhichToNotifyObservers,
				ISNULL(ST.Stage_Status,0) AS Stage_Status,
				ISNULL(ST.Stage_Started,0) AS Stage_Started,
				ST.Stage_Started_dt,
				ST.Stage_finished,
				ST.Stage_finished_dt,
				ST.Stage_current_iteration,
				ST.Stage_AwaitingFinancialApproval_Key,
				ISNULL(ST.Stage_was_skipped,0) AS Stage_was_skipped,
				ST.Stage_was_skipped_dt,
				ST.Stage_was_skipped_by_userid
			FROM
			[1i00_Central]..WFS_Task T
			JOIN [1i00_Central]..WFS_WorkFlowType W ON W.WorkFlowTypeCode=T.WFS_WorkFlowTypeCode
			JOIN [1i00_Central]..WFS_WorkflowType_Stages S ON S.WorkflowtypeCode=T.WFS_WorkFlowTypeCode AND S.Stage_IsActive=1
			LEFT JOIN [1i00_Central]..WFS_Item_Stages_Track ST ON
			(
				T.LibraryID=ST.LibraryID
			)
			AND
			(
				T.ItemSeqNo=ST.ItemSeqNo
			)
			AND
			S.WorkflowtypeCode=ST.WorkflowtypeCode
			AND
			S.StageCode=ST.StageCode
			WHERE T.ItemSeqNo=#arguments.itemSeqNo# AND T.LibraryID=#arguments.jwtData.SESSIONS.LibraryID# AND S.Stage_IsActive=1
			ORDER BY S.Stage_SeqNo ASC
		</cfquery>
        <!--- Loop through the query to build the JSON objects --->
		<cfset request.THIS_QWFS  = getWFitem>
		<cfset request.getWFitem = getWFitem> 
		<cfset request.THIS_getWFitem = getWFitem>
		<cfset request.THIS_qWFS = getWFitem>
		<cfset REQUEST.rsStageData = rsSubStageData>

		<cfset request.THIS_currentStageCode = arguments.currentStageCode>

		<cfset request.THIS_awaitingFinancialApproval_Key = "">
		<cfloop query="request.THIS_qStages">
			<cfif request.THIS_qStages.StageCode eq request.THIS_currentStageCode>
				<cfset request.THIS_awaitingFinancialApproval_Key = Stage_AwaitingFinancialApproval_Key>
			</cfif>
		</cfloop>
<!--- 		<cfset request.THIS_qStages = rsSubStageData> --->
<!--- <cfdump  var="#rsSubStageData#" label="rsSubStageData"	abort="true"> --->
        <cfloop query="rsSubStageData">
			<cfset request.this_workflow_is_active =
				(getWFitem.Item_is_deleted eq 0)
				and
				(getWFitem.Item_Status lt 2)
				and
				(getWFitem.Item_Status gt -2)
				and
				(getWFitem.Item_Status neq 0)
				>
			<cfset request.THIS_ItemSeqNo = rsSubStageData.ItemSeqNo>
			<Cfset theWorkflowItemSeqNo = rsSubStageData.ItemSeqNo>
			<cfset request.THIS_WFS_ID = theWorkflowItemSeqNo>
        	<cfset request.THIS_hasBeenLocated = true>
			
			<cfset request.THIS_WorkflowtypeCode = rsSubStageData.WorkFlowTypeCode>
			<cfif len(rsSubStageData.stageiterationno) gt 0>
				<cfset request.THIS_currentStageIterationNo = rsSubStageData.stageiterationno>
			<cfelse>
				<cfset request.THIS_currentStageIterationNo = 1>
			</cfif>
			
			<Cfset request.op_libraryid = rsSubStageData.LibraryID>
            <!--- Determine the responsibility description string based on the query data --->
            <cfif rsSubStageData.Responsibility_QTypeCode eq "Survey_Question">
                <cfset currentQuestion = APPLICATION.oSurveyUtilities.GetSurveyQuestionsStruct( SurveyID = rsSubStageData.Responsibility_miscDetails1,
				QuestionID = rsSubStageData.Responsibility_miscDetails2 )>
                <cfset responsibilityDescriptionString = UCase(currentQuestion.questionCategory) & "<br /><div style='margin: 5 0 0 13;'>" & currentQuestion.Question & "</div>">
            <cfelseif rsSubStageData.Responsibility_QTypeCode eq "Survey_Chart"
                    or rsSubStageData.Responsibility_QTypeCode eq "Standard_Multiple_File_Upload"
                    or rsSubStageData.Responsibility_QTypeCode eq "Standard_Multiple_File_Upload_Duplicate"
                    or rsSubStageData.Responsibility_QTypeCode eq "Survey_Chart_AllUsersSummary">
                <cfset responsibilityDescriptionString = "">
            <cfelseif rsSubStageData.Responsibility_QTypeCode eq "Label_BothSides">
                <cfset responsibilityDescriptionString = ListFirst(rsSubStageData.Responsibility_Description, "|")>
            <cfelseif rsSubStageData.Responsibility_QTypeCode eq "ParentQuestionDisplay">
                <cfset responsibilityDescriptionString = APPLICATION.oWorkflowParentQuestions.getParentQuestionAnswers( LibraryID = "#request.op_libraryID#",
                                                                                                                    ItemSeqNo = "#request.THIS_ItemSeqNo#",
                                                                                                                    MappingRef = "#rsSubStageData.Responsibility_ParentQuestion_Reference#",
                                                                                                                    CurrentAnswer = true ).Question>
            <cfelseif getWFitem.WorkFlowType_WFSSpecificType eq "alternateWFS">
                <cfset responsibilityDescriptionString = Replace(rsSubStageData.Responsibility_Description, "[replaceStoryboardLabel]", getWFitem.alternateWFSType_label, "all")>
                <cfif Find("[replaceStoryboardUser]", rsSubStageData.Responsibility_Description) neq 0>
                    <cfset inputVars=structnew()>
                    <cfset inputVars.doGetUnassignedToo=false>
                    <cfset inputVars.overrideStageCode = rsSubStageData.StageCode>
                    <cfmodule template="#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
                        ItemID="#getWFitem.ItemSeqNo#"
                        call="getParticipantsByStageQuery"
                        inputVars="#inputVars#"
                        var="fastReviewParticipantsByStage"
                    >
                    <cfloop query="fastReviewParticipantsByStage">
                        <cfif RoleCode eq Evaluate('request.wf_#Replace(getWFitem.WFS_WorkFlowTypeCode, "-", "_", "all")#Workflow_roleID_firstFileUploader')>
                            <cfset responsibilityDescriptionString = Replace(responsibilityDescriptionString, "[replaceStoryboardUser]", fastReviewParticipantsByStage.Name, "all")>
                        </cfif>
                    </cfloop>
                </cfif>
            <cfelseif rsSubStageData.Responsibility_QTypeCode eq "Money_Quote">
                <cfmodule template="#request.cfm_root_cfmapping#/smartgate/applications/1i00/wfsapi/1i00_wfs_qAlternateWFSCreateQuestions.tag"
                            query = "getAnswers"
                            itemSeqNo = "#getWFitem.ItemSeqNo#"
                            workflowTypeCode = "#getWFitem.WFS_WorkFlowTypeCode#"
                            alternateWFSType = "#request.THIS_altWFSTypeID#"
                            id = "1">
                <cfset theQuoteLetterPos = Asc(Mid(rsSubStageData.Responsibility_Description, 23, 1)) - 64><!--- ascii code for A --->
                <cfif ListLen(getAnswers.answer, "|") gte theQuoteLetterPos>
                    <cfset responsibilityDescriptionString = Replace(responsibilityDescriptionString, "(ex tax)", ": #ListGetAt(getAnswers.answer, theQuoteLetterPos, "|")#  (ex tax)")>
                </cfif>
            <cfelseif rsSubStageData.Responsibility_QTypeCode eq "CustomSelect_YesNo_QuantitiesABC">
                <cfinvoke component="#request.cfc_dot_notation_path#.WFSAPI.1i00_wfs_getSelectedQuote" method="getStruct"
                            wfSeqNo="#getWFitem.ItemSeqNo#"
                            returnVariable="quoteStruct">
                <cfset responsibilityDescriptionString = rsSubStageData.Responsibility_Description & "&nbsp;&nbsp;( #quoteStruct['selectedQuantity']# )">
            <cfelseif rsSubStageData.Responsibility_QTypeCode eq "CustomSelect_YesNo_DueDate">
                <cfset responsibilityDescriptionString = rsSubStageData.Responsibility_Description & "&nbsp;&nbsp;( #dateformat(getWFitem.Item_wf_DueDate,'dd/mm/yy')# )">
            <cfelse>
                <cfset responsibilityDescriptionString = rsSubStageData.Responsibility_Description>
            </cfif>
            <cfset REQUEST.getLibraryContext = APPLICATION.oLibrary.getLibraryContext(LibraryID=request.op_libraryid)>

			<cfif REQUEST.getLibraryContext.LibraryWorkflowLabelSingular neq "">
				<cfset workflowLabelSingular = REQUEST.getLibraryContext.LibraryWorkflowLabelSingular>
				<cfset workflowButtonNameSingular = workflowLabelSingular><!--- Replace(getLibraryContext.LibraryWorkflowLabelSingular, " ", "_", "all") LCase() --->
			<cfelse>
				<cfset workflowLabelSingular = "Workflow">
				<cfset workflowButtonNameSingular = "Workflow">
			</cfif>
			
		<!--- 			<cfset theWorkflowItemSeqNo = getWFitem.ItemSeqNo> --->
            <!--- Apply replacements to the responsibilityDescriptionString --->
            <cfset responsibilityDescriptionString = Replace( responsibilityDescriptionString, "|replaceAltWfsType|", getWFitem.alternateWFSType_label, "all" )>
            <cfset responsibilityDescriptionString = Replace( responsibilityDescriptionString, "|replaceWorklowLabel|", workflowLabelSingular, "all" )>
            <cfset responsibilityDescriptionString = Replace( responsibilityDescriptionString, "|replaceStageDesc|", rsSubStageData.Stage_Description, "all" )>
            <cfset responsibilityDescriptionString = Replace( responsibilityDescriptionString, "|replaceIteration|", rsSubStageData.stageiterationno, "all" )>
            <cfset responsibilityDescriptionString = Replace( responsibilityDescriptionString, "|replaceStageStartDateTime|", "#DateFormat(rsSubStageData.STAGE_STARTED_DT, 'd mmm yy')# at #TimeFormat(rsSubStageData.STAGE_STARTED_DT, 'hh:mm tt')#", "all" )>
            <cfif rsSubStageData.Responsibility_QTypeCode eq "Button_UpdateNotes_StageApprove_Approve">
				<Cfset currentQuesSendProofOnFinish = ( rsSubStageData.Responsibility_miscDetails2 eq "sendProofOnFinish" )>
				<cfif rsSubStageData.StageCode eq request.THIS_currentStageCode>
					<cfif rsSubStageData.currentRow eq rsSubStageData.recordCount
							and currentQuesSendProofOnFinish>
						<cfset request.moveJobNextStageText = "Print Proof">
						<cfset request.replaceMoveJobNextStage = APPLICATION.oTranslate.LookupLabel('I want a PRINT PROOF and to Finish the Job')><!--- I want a <b>PRINT PROOF</b> and to <b>Finish the Job</b> --->
					<cfelseif rsSubStageData.currentRow eq rsSubStageData.recordCount
							and not currentQuesSendProofOnFinish>
						<cfset request.moveJobNextStageText = "Finish Job">
						<cfset request.replaceMoveJobNextStage = APPLICATION.oTranslate.LookupLabel('I want to Finish the Job')><!--- I want to <b>Finish the Job</b> --->
					<cfelse>
						<cfset request.moveJobNextStageText = "Next Stage"><!--- BH 9/11/2016 - stage name is too long and variable to put in button so just have "Next Stage" <cfset request.moveJobNextStageText = rsSubStageData.Stage_Description[rsSubStageData.currentRow+1]> --->
						<cfset request.replaceMoveJobNextStage = "#APPLICATION.oTranslate.LookupLabel('I want to move job forward to')# <b>#rsSubStageData.Stage_Description[rsSubStageData.currentRow+1]#</b>"><!--- I want to <b>move job forward</b> to #rsSubStageData.Stage_Description[rsSubStageData.currentRow+1]# --->
					</cfif>
				</cfif>
				<cfset responsibilityDescriptionString = Replace( responsibilityDescriptionString, "|replaceMoveJobNextStage|", request.replaceMoveJobNextStage, "all" )>
				</cfif>
			<cfif rsSubStageData.ResponsibilityValue_Input_Override neq "">
				<cfset answerOverrideDetails = "Revised - #rsSubStageData.ResponsibilityValue_Input_Override_UserFirstName# #rsSubStageData.ResponsibilityValue_Input_Override_UserLastName# - #DateFormat( ResponsibilityValue_Input_Override_dt, 'd mmm yyyy' )# - #TimeFormat( ResponsibilityValue_Input_Override_dt, 'HH:mm' )#">
				<cfset useRespValueInput = rsSubStageData.ResponsibilityValue_Input_Override>
			<cfelse>
				<cfset answerOverrideDetails = "">
				<cfset useRespValueInput = rsSubStageData.ResponsibilityValue_Input>
			</cfif>

			<cfif not IsDefined("respSpecificSelectsStruct")>
				<cfmodule template="#request.smartgate#applications/1i00/1i00_WFS_API.cfm"
					call="getResponsibilitySpecificSelects"
					ItemID="#rsSubStageData.ItemSeqNo#"
					var="respSpecificSelectsStruct"
				>
			</cfif>		

			<cfif rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_Use_Intermediate_Date" or rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_Use_Intermediate_Due_Dates" or rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_No_Dates">
				<cfset alternateWFSType_workflowTypeCode = getWFitem.WFS_WorkFlowTypeCode>

				<cfinclude template="#APPLICATION.URI.1i00#/wfsapi/1i00_wfs_qalternateWFSTypes.q">
			</cfif>	

			<cfmodule template="#request.smartgate#applications/1i00/1i00_WFS_API.cfm"
				ItemID="#rsSubStageData.ItemSeqNo#"
				call="getArtworkFileName"
				pStage="#rsSubStageData.StageCode#"
				pIteration="#request.THIS_currentStageIterationNo#"
				var="theArtworkFileName"
			>	

			<cfset request.form0_theArtworkFileName=theArtworkFileName>

			<cfmodule template="#request.smartgate#applications/1i00/1i00_WFS_API.cfm"
				ItemID="#rsSubStageData.ItemSeqNo#"
				pStage="#rsSubStageData.StageCode#"
				call="getLastIterationNoForStage"
				var="lastIterationNo_for_required_stage"
				>

			<cfset reqIterationNo = lastIterationNo_for_required_stage>
			<cfset REQUEST.reqIterationNo = reqIterationNo>
			<Cfset request.alreadyIncluded_JS_SHOW_HIDE_scripts = true>

			<cfset request.ItemSeqNo = rsSubStageData.ItemSeqNo>

			<cfset REQUEST.THEWORKFLOWITEMSEQNO = rsSubStageData.ItemSeqNo>		
			<cfset session.canDownloadStandardFileSeqNo = StructNew()>
			<cfset theWorkflowItemSeqNo = rsSubStageData.ItemSeqNo>
			<cfset session.canDownloadStandardFileSeqNo[theWorkflowItemSeqNo] = StructNew()>
			<cfset session.canDownloadCurrentRTIFileSeqNo[theWorkflowItemSeqNo] = StructNew()>

			<cfset qVProofDetails = APPLICATION.oVProofAppSpecific.getFileDetails( itemSeqNo = theWorkflowItemSeqNo,
																stageCode = rsSubStageData.StageCode,
																version = reqIterationNo,
																excludeWfStandardFiles = true )>			

			<!--- if artwork not viewed then no data in table so set as VP for default --->
			<cfif qVProofDetails.jobCommentsMethod eq "">
				<cfif Left(qVProofDetails.VProofFilename, 4) eq "\Lib">
					<cfset usejobCommentsMethod = "VP">
				<cfelse>
					<cfset usejobCommentsMethod = "RTI">
				</cfif>
			<cfelse>
				<cfset usejobCommentsMethod = qVProofDetails.jobCommentsMethod>
			</cfif>

			<cfset request.rtiDownload_fileRoot = Evaluate("REQUEST.VProof_fileRoot_#usejobCommentsMethod#")><!--- REQUEST.VProof_fileRoot_VP --->
			<cfset request.rtiDownload_fileNamePath = "#qVProofDetails.VProofFilepathSub#\#qVProofDetails.VProofFilename#">
			<cfset request.rtiDownload_originalFilename = qVProofDetails.FileOrigName>			
 			<cfinclude template="#APPLICATION.URI.1i00#/1i00_wfs_INIT_hasFile_hasProfingFile.inc"> 


			<cfset request.form0_hasArtworkFileToReview=hasArtworkFileToReview>
			<cfset request.form0_hasProofingFileToReview=hasProofingFileToReview>

			
			<cfscript>
				dropdownDataArray = ArrayNew(2);

				if ( rsSubStageData.Responsibility_QTypeCode eq "Country" )
					theValuesCount = ArrayLen(countriesArray);

				else if ( rsSubStageData.Responsibility_QTypeCode eq "Custom_Select"
								OR rsSubStageData.Responsibility_QTypeCode eq "Custom_Select_OpenOtherStageOnLast"
								OR rsSubStageData.Responsibility_QTypeCode eq "DAM_Resource_Link_Predefined_Select" )
					theValuesCount = rsSubStageData.QType_Custom_ValuesCount;

				else if ( rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_Use_Intermediate_Date" or rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_Use_Intermediate_Due_Dates" or rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_No_Dates" )
					theValuesCount = qalternateWFSTypes.recordCount;

				else if ( rsSubStageData.Responsibility_QTypeCode eq "Responsibility_Specific_Selects" ){
					theValuesCount = ArrayLen( respSpecificSelectsStruct.value[rsSubStageData.ResponsibilityCode] );
					if( rsSubStageData.Responsibility_QTypeSubCode eq "Regular_Select" ){
						temp = ArrayAppend(dropdownDataArray[1], "" );
						temp = ArrayAppend(dropdownDataArray[2], "Please Select" );
						temp = ArrayAppend(dropdownDataArray[3], "comma" );	/*respSpecificSelectsStruct.dividerType[1]*/
					}

				} else
					theValuesCount = rsSubStageData.QType_ValuesCount;

				if (theValuesCount neq 0){
					for (dropdownDataIndex = 1; dropdownDataIndex lte theValuesCount; dropdownDataIndex=dropdownDataIndex+1){
						/* if QuoteFlow need to specify which of three quants (A,B or C) have agreed to print */
						if ( rsSubStageData.Responsibility_QTypeCode eq "Country" ) {
							temp = ArrayAppend(dropdownDataArray[1], countriesArray[dropdownDataIndex].code);
							temp = ArrayAppend(dropdownDataArray[2], countriesArray[dropdownDataIndex].name);
						} else if ( rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_Use_Intermediate_Date" or rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_Use_Intermediate_Due_Dates" or rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_No_Dates" ) {
							temp = ArrayAppend(dropdownDataArray[1], qalternateWFSTypes.alternateWFSType_id[dropdownDataIndex]);
							temp = ArrayAppend(dropdownDataArray[2], qalternateWFSTypes.alternateWFSType_label[dropdownDataIndex]);
						} else 	if ( rsSubStageData.Responsibility_QTypeCode eq "Custom_Select"
											OR rsSubStageData.Responsibility_QTypeCode eq "Custom_Select_OpenOtherStageOnLast"
											OR rsSubStageData.Responsibility_QTypeCode eq "DAM_Resource_Link_Predefined_Select" ) {
							temp = ArrayAppend(dropdownDataArray[1], Evaluate("rsSubStageData.QType_Custom_Value"&dropdownDataIndex));
							temp = ArrayAppend(dropdownDataArray[2], Evaluate("rsSubStageData.QType_Custom_Label"&dropdownDataIndex));
						} else if ( rsSubStageData.Responsibility_QTypeCode eq "Radio_QuantitiesABC"
										or rsSubStageData.Responsibility_QTypeCode eq "Radio_ConceptABC" ) {
							if (createQuestionQuantity[dropdownDataIndex] neq "") {
								temp = ArrayAppend(dropdownDataArray[1], Evaluate("rsSubStageData.QType_Value"&dropdownDataIndex));
								temp = ArrayAppend(dropdownDataArray[2], Evaluate("rsSubStageData.QType_Label"&dropdownDataIndex) );
								if ( rsSubStageData.Responsibility_QTypeCode eq "Radio_QuantitiesABC" )
									dropdownDataArray[2][ ArrayLen(dropdownDataArray[2]) ] = dropdownDataArray[2][ ArrayLen(dropdownDataArray[2]) ] & "&nbsp;(#createQuestionQuantity[dropdownDataIndex]#)";
							}
						} else if ( rsSubStageData.Responsibility_QTypeCode eq "Responsibility_Specific_Selects" ) {
							temp = ArrayAppend(dropdownDataArray[1], respSpecificSelectsStruct.value[rsSubStageData.ResponsibilityCode][dropdownDataIndex] );
							temp = ArrayAppend(dropdownDataArray[2], respSpecificSelectsStruct.text[rsSubStageData.ResponsibilityCode][dropdownDataIndex] );
							temp = ArrayAppend(dropdownDataArray[3], respSpecificSelectsStruct.dividerType[rsSubStageData.ResponsibilityCode][dropdownDataIndex] );
							temp = ArrayAppend(dropdownDataArray[4], respSpecificSelectsStruct.optionID[rsSubStageData.ResponsibilityCode][dropdownDataIndex] );
						} else {
							temp = ArrayAppend(dropdownDataArray[1], Evaluate("rsSubStageData.QType_Value"&dropdownDataIndex));
							temp = ArrayAppend(dropdownDataArray[2], Evaluate("rsSubStageData.QType_Label"&dropdownDataIndex));
						}

					}
				}

				if ( rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_Use_Intermediate_Date" or rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_Use_Intermediate_Due_Dates" or rsSubStageData.Responsibility_QTypeCode eq "Select_Workflow_SubType_No_Dates" ){
					temp = ArrayPrepend( dropdownDataArray[1], "" );
					temp = ArrayPrepend( dropdownDataArray[2], "Please Select" );
				}
			</cfscript>

			<cfset isReallyJustAPreviewOnly = 0>
			<cfset displayvisualhintforrequired = 0>
			<cfset rolecontext="role">
			<cfset for_this_user = 1>
			<cfset approveSection = rsSubStageData.Responsibility_IsStageDecisionPoint >
			<cfset fullWidth = 1>
			<cfset this_role_section_rolecode = rsSubStageData.RoleCode>
			
			<cfset request.theDesignForPrepressFileName = StructNew()>
			<cfset request.theDesignForPrepressFileName.original = rsSubStageData.WFS_DesignForPrepress_Filename_Saved>
			<cfset request.theDesignForPrepressFileName.original_PDF = rsSubStageData.WFS_DesignForPrepress_PDF_Filename_Saved>
			<cfset request.theDesignForPrepressFileName.save = rsSubStageData.WFS_DesignForPrepress_Filename_Original>
			<cfset request.theDesignForPrepressFileName.save_PDF = rsSubStageData.WFS_DesignForPrepress_PDF_Filename_Original>
			
			<Cfset request.THIS_qWFS.WFS_Proofing_ID = getWFitem.WFS_Proofing_ID>
			<cfmodule template="#request.smartgate#applications/1i00/1i00_WFS_API.cfm"
				ItemID="#rsSubStageData.ItemSeqNo#"
				call="getProofingFileName"
				pStage="#rsSubStageData.StageCode#"
				pIteration="1"
				getFinalCorrectedProof="#rsSubStageData.Stage_IsFinalCorrectedProof#"
				var="theProofingFileName"
			>
			<cfset request.form0_theProofingFileName = theProofingFileName>
			<cfif not StructKeyExists(REQUEST, "roleQuestionsToLockAfterFinish")>
				<cfset REQUEST.roleQuestionsToLockAfterFinish = StructNew()>
			</cfif>
			<cfif not StructKeyExists(REQUEST.roleQuestionsToLockAfterFinish, this_role_section_rolecode)>
				<cfset REQUEST.roleQuestionsToLockAfterFinish[this_role_section_rolecode] = StructNew()>
			</cfif>
			
			<cfset REQUEST.roleQuestionsToLockAfterFinish[this_role_section_rolecode][rsSubStageData.ResponsibilityCode] = "editIcon">	

			<cfmodule template="#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
				ItemID="#rsSubStageData.ItemSeqNo#"
				call="getStandardFiles"
				pStage="#request.THIS_currentStageCode#"
				pIteration="#request.THIS_currentStageIterationNo#"
				workflowtypeCode="#request.THIS_WorkflowtypeCode#"
				var="theStandardFiles"
			>
			<cfset request.theStandardFiles = theStandardFiles>
			
			<cfmodule template = "#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
				ItemID = "#request.THIS_ItemSeqNo#"
				call = "getCopyFilesToDAMBinsPostFinish"
				var = "copyFilesToDAMBinsPostFinish"
			>
			
			<Cfset request.op_userid = jwtData.sessions.userid>

			<cfmodule template="#request.smartgate#applications/1i00/1i00_WFS_API.cfm"
				ItemID="#request.THIS_ItemSeqNo#"
				call="getStructOfAllRolesForThisUser"
				var="structOfAllRolesForThisUser"
				skipRolesAssignedDuringWF = true
			>

			<cfscript>
				function okDoesThisUserHaveThisRole(rc){
					var r = structkeyexists(structOfAllRolesForThisUser,rc);
					return r;
				}
				function includeAjaxIconCode( argFieldname ){
					if( FindNoCase("msie", cgi.http_user_agent) neq 0
							and FindNoCase("mac", cgi.http_user_agent) neq 0 )
						return "";
					else
						return " document.ajaxIcon_question_#argFieldname#.src = ajaxIconOnImage.src; ";
				}
				request.includeAjaxIconCode = includeAjaxIconCode;
			</cfscript>			

			<cfset for_this_user = okDoesThisUserHaveThisRole(rsSubStageData.RoleCode)>
			<cfset this_role_section_is_for_this_user = for_this_user>

			<cfset this_role_section_rolecode = rsSubStageData.RoleCode>
			<cfset this_role_section_rolecode = rsSubStageData.RoleCode>
			<cfset this_role_section_displayTheAbstainOption = rsSubStageData.StageRole_displayTheAbstainOption>
			<cfset this_role_section_AllowFinishWhenOneRequiredRespDone = rsSubStageData.StageRole_AllowFinishWhenOneRequiredRespDone>


			<cfset this_role_section_isopen =
				(rsSubStageData.Stage_IsRequiringRoleSectionsPrioritization eq 0)
				or
				(rsSubStageData.RST_IsOpen eq 1)
			>


			<cfset this_user_rolecode = this_role_section_rolecode>
			<cfset this_user_abstain = rsSubStageData.abstain_from_participation>
			<cfset abstain_from_participation = rsSubStageData.abstain_from_participation>

			<cfset this_stage_is_finished = (rsSubStageData.Stage_finished eq 1)>
			<cfset run_for_IsStageDecisionPoint = arguments.run_for_IsStageDecisionPoint>
			<cfif (run_for_IsStageDecisionPoint eq 0)>
				<cfset this_role_section_is_finished = (rsSubStageData.RoleSection_isFinished eq 1)>
			<cfelse>
				<cfset this_role_section_is_finished = this_stage_is_finished>
			</cfif>

			<cfif run_for_IsStageDecisionPoint eq 1>
				<cfset this_role_section_has_general_comments = false>
			<cfelse>
				<cfset this_role_section_has_general_comments = rsSubStageData.StageRole_hasGeneralRoleComments eq 1>
			</cfif>

			<cfset canCurrentStageBeApproved = APPLICATION.oWorkflowUtilities.canCurrentStageBeApproved( ItemSeqNo = request.THIS_ItemSeqNo)>
			<cfset isPreviewOnly = not canCurrentStageBeApproved>

			<Cfset request.UG_userIsWorkflowAdmin = 1>

			<cfset this_role_section_IS_AVAILABLE_FOR_THIS_USER
				=
					this_role_section_is_for_this_user
					and
					(isPreviewOnly)
					and
					this_role_section_isopen
			>

			<Cfset readOnly = 0>

			<cfset this_role_section_IS_EXPOSED_FOR_THIS_USER_INPUT
				=
					this_role_section_IS_AVAILABLE_FOR_THIS_USER
					and
					(readOnly eq 0)
					and
					(not this_role_section_is_finished)
					and
					abstain_from_participation eq 0
					and
					RST_IsSkipping eq 0
			>
			<Cfset request.THIS_WFS_ID = getWFitem.ItemSeqNo>
			<cfinvoke component="#request.cfc_dot_notation_path#.WFSAPI.1i00_wfs_canSeeOtherRolesPublicPrivate"
				method="canSeeOtherRolesPublicPrivate"
				ItemSeqNo="#request.THIS_WFS_ID#"
				returnVariable="canSeeOtherRoles">

			<cfset isThisResponsibilityInputInAciveState = false>
			<cfset isThisResponsibilityInputInAciveState = this_role_section_IS_EXPOSED_FOR_THIS_USER_INPUT
			OR ( rsSubStageData.Responsibility_ActiveAfterFinish eq 1
						and ( this_role_section_is_for_this_user
									or ListFindNoCase(REQUEST.interactStaffEmailList, GetToken(request.getUserProfile.email, 2, "@") ) gt 0 )
						and not request.this_workflow_is_active
						and (
								not copyFilesToDAMBinsPostFinish.functionalityActive
								or ( copyFilesToDAMBinsPostFinish.functionalityActive
										and copyFilesToDAMBinsPostFinish.respCode neq rsSubStageData.ResponsibilityCode )
								or ( copyFilesToDAMBinsPostFinish.functionalityActive
										and copyFilesToDAMBinsPostFinish.status eq "ToDo"
										and getWFitem.Item_FinishedArt_RUID eq "" )
								or ( copyFilesToDAMBinsPostFinish.functionalityActive
										and copyFilesToDAMBinsPostFinish.status neq "ToDo"
										and ListFindNoCase(REQUEST.interactStaffEmailList, GetToken(request.getUserProfile.email, 2, "@") ) gt 0 )
							)
					)
			OR ( rsSubStageData.Responsibility_ActiveUntilWorkflowFinish eq 1
						and this_role_section_is_for_this_user
						and request.this_workflow_is_active )
			OR (
						( canSeeOtherRoles.canReopenNewVersion
								or request.UG_userIsWorkflowAdmin eq 1 )
						and rsSubStageData.Responsibility_QTypeCode eq "Button_ReopenJob_NewVersion"
					)
			>		
		<!--- 			<cfdump  var="#isThisResponsibilityInputInAciveState#" abort="true"> --->
			<cfset request.UG_userIsWorkflowAdmin = 1>
			<cfset THEWORKFLOWITEMSEQNO = request.THIS_WFS_ID>
			<Cfset REQUEST.jsGetMouseDefined = true>
			
			<cfscript>
				if (isThisResponsibilityInputInAciveState)
					{
						whichCallBack="doUpdate_#rolecontext#_#this_role_section_rolecode#";
						// if (qtypecode eq "req_Iteration")	{
						// 	whichCallBack="doRefreshAfterIterationRequest";
						// } else if (qtypecode eq "Upload_RUID"
						// 					or qtypecode eq "Upload_PROOF"
						// 					or qtypecode eq "Upload_Corrected_PROOF"){
						// 	whichCallBack="#URLEncodedFormat("parent.location.href='#APPLICATION.URI.1i00#/1i00_workflow_list.cfm?wfsFormFramesetAction=frameset_questions&theWorkflowItemSeqNo=#getWFitem.ItemSeqNo#';")#";
						// 	/*<!--- whichCallBack="doUpdateAllFrames_#rolecontext#_#this_role_section_rolecode#"; --->*/
						// }
					}

			</cfscript>	

			<cfset hiddenByOtherQuestion = false>
			<cfmodule template="#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
				ItemID="#THEWORKFLOWITEMSEQNO#"
				pStage="#request.THIS_currentStageCode#"
				pIteration=""
				call="getStageDataQuery"
				var="dependentAnswersStageData"
				filterByAbstainParticipation=false
				filterHiddenDependantQuestions=false
			>
			<cfset REQUEST.respCodeAnsweredPositiveStruct = StructNew()>
			<!--- used to hide questions until other question has been answered EITHER YES OR NO, to enforce a form of staging within role --->
			<cfset REQUEST.respCodeAnsweredNegativeStruct = StructNew()>
			<!--- used to hide questions until other question has been selected to LAST VALUE in dropdown, to enforce a form of staging within role --->
			<cfset REQUEST.respCodeAnsweredLastValueStruct = StructNew()>
			<cfif LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "yes"
					or LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "done"
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_CorrectionsDesignerPrepress"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "designer"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "AllocateUserToRole_CopyRoleAToRoleB"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) neq "No"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_GTIN13_GTIN8"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "gtin13gtin8_gtin13"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_GTIN8GTIN13_GTIN14"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "gtin8gtin13gtin14_gtin8gtin13"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_AsPerCurrentNew"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "aspercurrentnew_aspercurrent"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_InnerOuter"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "innerouter_inner"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_InnerOuterPIL"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "innerouterpil_inner"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_ScheduleSignalHeading"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "schedulesignalheading_pharmacistonlymedicine"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "Button_ReopenStageRole"
							and dependentAnswersStageData.ResponsibilityValue_Input  neq ""
						)
			>
				<cfset REQUEST.respCodeAnsweredPositiveStruct["#dependentAnswersStageData.ResponsibilityCode#"] = 1>
			</cfif>

			<!--- used to hide questions until other question has been answered NO, to enforce a form of staging within role --->
			<cfif ( ListFindNoCase("CustomSelect_CorrectionsDesignerPrepress,CustomSelect_GTIN13_GTIN8,CustomSelect_GTIN8GTIN13_GTIN14,CustomSelect_AsPerCurrentNew,CustomSelect_InnerOuter,CustomSelect_InnerOuterPIL,CustomSelect_ScheduleSignalHeading", dependentAnswersStageData.Responsibility_QTypeCode) eq 0
						AND Trim(dependentAnswersStageData.ResponsibilityValue_Input) neq ""
						AND LCase(dependentAnswersStageData.ResponsibilityValue_Input) neq "yes"
						AND LCase(dependentAnswersStageData.ResponsibilityValue_Input) neq "done" )
					OR
					( dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_CorrectionsDesignerPrepress"
						AND LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "prepress" )
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_GTIN13_GTIN8"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "gtin13gtin8_gtin8"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_GTIN8GTIN13_GTIN14"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "gtin8gtin13gtin14_gtin14"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_AsPerCurrentNew"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "aspercurrentnew_new"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_InnerOuter"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "innerouter_outer"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_InnerOuterPIL"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "innerouterpil_outer"
						)
					or (
							dependentAnswersStageData.Responsibility_QTypeCode eq "CustomSelect_ScheduleSignalHeading"
							and LCase(dependentAnswersStageData.ResponsibilityValue_Input) eq "schedulesignalheading_pharmacymedicine"
						)
			>
				<cfset REQUEST.respCodeAnsweredNegativeStruct["#dependentAnswersStageData.ResponsibilityCode#"] = 1>
			</cfif>
			<!--- only pass dependentAnswers_CustomSelectLastValue if is CustomSelect question type --->
			<cfif Left( dependentAnswersStageData.Responsibility_QTypeCode, 12 ) eq "CustomSelect"
					OR Left( dependentAnswersStageData.Responsibility_QTypeCode, 13 ) eq "Custom_Select">

				<cfif dependentAnswersStageData.QType_ValuesCount gt 0>

					<cfset dependentAnswers_CustomSelectLastValue = Evaluate("dependentAnswersStageData.QType_Value#dependentAnswersStageData.QType_ValuesCount#")>

					<cfif LCase(dependentAnswers_CustomSelectLastValue) eq LCase(dependentAnswersStageData.ResponsibilityValue_Input)>
						<cfset REQUEST.respCodeAnsweredLastValueStruct["#dependentAnswersStageData.ResponsibilityCode#"] = 1>
					</cfif>

				</cfif>

			</cfif>

		


			<!--- LL UI 2022-04-26 logic tidy - START --->
			<cfif ( rsSubStageData.hiddenUntilOtherRespCodeAnsweredPositive neq "" and not StructKeyExists(REQUEST.respCodeAnsweredPositiveStruct, rsSubStageData.hiddenUntilOtherRespCodeAnsweredPositive) )
			OR
			( rsSubStageData.hiddenUntilOtherRespCodeAnsweredPositive2 neq "" and not StructKeyExists(REQUEST.respCodeAnsweredPositiveStruct, rsSubStageData.hiddenUntilOtherRespCodeAnsweredPositive2) )>
				<cfset hiddenByOtherQuestion = true>
			</cfif>

			
			<cfif ( rsSubStageData.hiddenUntilOtherRespCodeAnsweredPositive neq "" OR rsSubStageData.hiddenUntilOtherRespCodeAnsweredPositive2 neq "" )
					and rsSubStageData.qtypecode eq "Button_ResendProof"
					and request.THIS_qWFS.WFS_ProofRequested neq 1>
				<cfset hiddenByOtherQuestion = true>
				<cfset respHiddenNoFinishButton = true>
			</cfif>

			<cfif ( rsSubStageData.HiddenUntilOtherRespCodeAnsweredNegative neq "" and not StructKeyExists(REQUEST.respCodeAnsweredNegativeStruct, rsSubStageData.HiddenUntilOtherRespCodeAnsweredNegative) )
			OR
			( rsSubStageData.HiddenUntilOtherRespCodeAnsweredNegative2 neq "" and not StructKeyExists(REQUEST.respCodeAnsweredNegativeStruct, rsSubStageData.HiddenUntilOtherRespCodeAnsweredNegative2) )>
				<cfset hiddenByOtherQuestion = true>
			</cfif>

			<cfif ( rsSubStageData.HiddenUntilOtherRespCodeAnsweredLastValue neq "" and not StructKeyExists(REQUEST.respCodeAnsweredLastValueStruct, rsSubStageData.HiddenUntilOtherRespCodeAnsweredLastValue) ) 
			OR
			( rsSubStageData.HiddenUntilOtherRespCodeAnsweredLastValue2 neq "" and not StructKeyExists(REQUEST.respCodeAnsweredLastValueStruct, rsSubStageData.HiddenUntilOtherRespCodeAnsweredLastValue2) )>
				<cfset hiddenByOtherQuestion = true>
			</cfif>

			<cfif ( rsSubStageData.HiddenIfOtherRespCodeAnsweredYes neq "" and StructKeyExists(REQUEST.respCodeAnsweredPositiveStruct, rsSubStageData.HiddenIfOtherRespCodeAnsweredYes) )
			OR
			( rsSubStageData.HiddenIfOtherRespCodeAnsweredYes2 neq ""	and StructKeyExists(REQUEST.respCodeAnsweredPositiveStruct, rsSubStageData.HiddenIfOtherRespCodeAnsweredYes2) )>
				<cfset hiddenByOtherQuestion = true>
			</cfif>

			<cfif ( rsSubStageData.HiddenIfOtherRespCodeAnsweredYes neq "" or rsSubStageData.HiddenIfOtherRespCodeAnsweredYes2 neq "" )
					and rsSubStageData.qtypecode eq "Button_ResendProof"
					and request.THIS_qWFS.WFS_ProofRequested eq 1>
				<cfset hiddenByOtherQuestion = true>
				<cfset respHiddenNoFinishButton = true>
			</cfif>

			<cfif ( rsSubStageData.HiddenIfOtherRespCodeAnsweredNo neq "" and StructKeyExists(REQUEST.respCodeAnsweredNegativeStruct, rsSubStageData.HiddenIfOtherRespCodeAnsweredNo) )
			OR
			( rsSubStageData.HiddenIfOtherRespCodeAnsweredNo2 neq "" and StructKeyExists(REQUEST.respCodeAnsweredNegativeStruct, rsSubStageData.HiddenIfOtherRespCodeAnsweredNo2) )>
				<cfset hiddenByOtherQuestion = true>
			</cfif>			

			<cfset canFinishStruc=structnew()>
			<cfset this_role_section_canFinish = true>
			<cfset last_RoleCode = rsSubStageData.RoleCode>
			<cfset this_role_section = rsSubStageData.RoleCode>
			<cfset canFinishStruc[last_RoleCode]=this_role_section_canFinish>
			
			<cfif REQUEST.getLibraryContext.LibraryWorkflowLabelSingular neq "">
				<cfset request.workflowLabelSingular = REQUEST.getLibraryContext.LibraryWorkflowLabelSingular>
				<cfset request.workflowButtonNameSingular = request.workflowLabelSingular><!--- Replace(getLibraryContext.LibraryWorkflowLabelSingular, " ", "_", "all") LCase() --->
			<cfelse>
				<cfset request.workflowLabelSingular = "Workflow">
				<cfset request.workflowButtonNameSingular = "Workflow">
			</cfif>
			<cfset theWorkflowItemSeqNo = rsSubStageData.ItemSeqNo>
		<cftry>
			<cfsavecontent  variable="Answer">
				<cfif rsSubStageData.Responsibility_visibleForIteration eq "first" and request.THIS_currentStageIterationNo gt 1>
					<div title='Question Only Active Version 1' style='width:200px;'>&nbsp;</div>
					<!--- <span class="i00_text_tiny_gray">Only Active Version 1&nbsp;&nbsp;</span> --->
				
				<cfelse>
					<cfmodule template="#APPLICATION.URI.1i00#/1i00_wfs_cftag_formathtmldisplayfield.TAG"
						fieldname="r_#rsSubStageData.ResponsibilityCode#"
						qtypecode="#rsSubStageData.Responsibility_QTypeCode#"
						qtypesubcode="#rsSubStageData.Responsibility_QTypeSubCode#"
						value="#useRespValueInput#"
						valueExtraData="#rsSubStageData.ResponsibilityValue_Input_extraData#"
						valueNtext="#rsSubStageData.ResponsibilityValue_Input_ntext#"
						formname="wfs_#rolecontext#_#this_role_section_rolecode#"
						required="#rsSubStageData.Responsibility_IsRequired#"
						decisionpoint="#rsSubStageData.Responsibility_IsStageDecisionPoint#"
						ispurepreview="#isReallyJustAPreviewOnly#"
						requiredpositive="#rsSubStageData.Responsibility_IsRequiredPositive#"
						rolecontext="#rolecontext#"
						dovisualhintforrequired="#displayvisualhintforrequired#"
						callback="doRefreshAfterIterationRequest"
						dropdownDataArray="#dropdownDataArray#"
						textNote = "#rsSubStageData.ResponsibilityValue_Input_TextNote#"
						stagecode="#rsSubStageData.StageCode#"
						rolecode="#rsSubStageData.RoleCode#"
						IsWorkflowManager="#rsSubStageData.Role_IsWorkflowManager#"
						responsibilitycode="#rsSubStageData.ResponsibilityCode#"
						forthisuser = "#for_this_user#"
						approveSection="#approveSection#"
						Responsibility_Description = "#rsSubStageData.Responsibility_Description#"
						Responsibility_DescriptionShort = "#rsSubStageData.Responsibility_DescriptionShort#"
						Responsibility_forceTextNote = "#rsSubStageData.Responsibility_forceTextNote#"
						Responsibility_miscDetails1 = "#rsSubStageData.Responsibility_miscDetails1#"
						Responsibility_miscDetails2 = "#rsSubStageData.Responsibility_miscDetails2#"
						Responsibility_miscDetails3 = "#rsSubStageData.Responsibility_miscDetails3#"
						Responsibility_miscDetails4 = "#rsSubStageData.Responsibility_miscDetails4#"
						Responsibility_ParentQuestion_Reference = "#rsSubStageData.Responsibility_ParentQuestion_Reference#"
						Responsibility_StandardFile_Number = "#rsSubStageData.Responsibility_StandardFile_Number#"
						Responsibility_StandardFile_UseProofingClient = "#rsSubStageData.Responsibility_StandardFile_UseProofingClient#"
						Responsibility_StandardFile_DetailedFileInfo_Generate="#rsSubStageData.Responsibility_StandardFile_DetailedFileInfo_Generate#"
						Responsibility_StandardFile_DetailedFileInfo_Display="#rsSubStageData.Responsibility_StandardFile_DetailedFileInfo_Display#"
						Responsibility_StandardFile_Display_SmartMedia_Metadata="#rsSubStageData.Responsibility_StandardFile_Display_SmartMedia_Metadata#"
						Responsibility_StandardFile_ValidateUploadAgainstStandard="#rsSubStageData.Responsibility_StandardFile_ValidateUploadAgainstStandard#"
						Responsibility_StandardFile_ValidateUploadAgainstStandard_PreventFinish="#rsSubStageData.Responsibility_StandardFile_ValidateUploadAgainstStandard_PreventFinish#"
						helpText = "#rsSubStageData.Responsibility_helpText#"
						WorkFlowType_UseFDF = "#request.overrideWorkflowUseFDF( rsSubStageData.WorkFlowTypeCode , rsSubStageData.WorkFlowType_UseFDF )#"
						WorkFlowTypeCode = "#rsSubStageData.WorkFlowTypeCode#"
						ItemSeqNo = "#rsSubStageData.ItemSeqNo#"
						fullWidth = #fullWidth#
						useFieldLock = "#rsSubStageData.QType_useFieldLock#"
						answerOverrideDetails = "#answerOverrideDetails#"
						OverrideButtonLabel = "#rsSubStageData.Responsibility_OverrideButtonLabel#"
						OverrideButtonWidth = "#rsSubStageData.Responsibility_OverrideButtonWidth#"
						OverrideButtonStyle = "#rsSubStageData.Responsibility_OverrideButtonStyle#"
						QType_DefaultButtonLabel = "#rsSubStageData.QType_DefaultButtonLabel#"
						QType_DefaultButtonWidth = "#rsSubStageData.QType_DefaultButtonWidth#"
						QType_DefaultButtonStyle = "#rsSubStageData.QType_DefaultButtonStyle#"
						Responsibility_LogAnswer = "#rsSubStageData.Responsibility_LogAnswer#"
						Responsibility_HideNormalStageFinishButton = "#rsSubStageData.Responsibility_HideNormalStageFinishButton#"
					>
				</cfif>		
			</cfsavecontent>

			<cfsavecontent  variable="IsActiveQuestions">
				<Cfif isThisResponsibilityInputInAciveState>
				<cfmodule template="#APPLICATION.URI.1i00#/1i00_wfs_cftag_formathtmlinputfield.TAG"
						fieldname="r_#rsSubStageData.ResponsibilityCode#"
						qtypecode="#rsSubStageData.Responsibility_QTypeCode#"
						qtypesubcode="#rsSubStageData.Responsibility_QTypeSubCode#"
						value="#useRespValueInput#"
						valueExtraData="#rsSubStageData.ResponsibilityValue_Input_extraData#"
						valueNtext="#rsSubStageData.ResponsibilityValue_Input_ntext#"
						formname="wfs_#rolecontext#_#this_role_section_rolecode#"
						required="#rsSubStageData.Responsibility_IsRequired#"
						decisionpoint="#rsSubStageData.Responsibility_IsStageDecisionPoint#"
						ispurepreview="#isReallyJustAPreviewOnly#"
						requiredpositive="#rsSubStageData.Responsibility_IsRequiredPositive#"
						rolecontext="#rolecontext#"
						callback="#whichCallBack#"
						dropdownDataArray="#dropdownDataArray#"
						hasTextNote="#rsSubStageData.Responsibility_hasTextNote#"
						textNote = "#rsSubStageData.ResponsibilityValue_Input_TextNote#"
						canFinish="#canFinishStruc[this_role_section_rolecode]#"
						stagecode="#rsSubStageData.StageCode#"
						rolecode="#rsSubStageData.RoleCode#"
						IsWorkflowManager="#rsSubStageData.Role_IsWorkflowManager#"
						responsibilitycode="#rsSubStageData.ResponsibilityCode#"
						approveSection="#approveSection#"
						Responsibility_Description = "#rsSubStageData.Responsibility_Description#"
						Responsibility_DescriptionShort = "#rsSubStageData.Responsibility_DescriptionShort#"
						Responsibility_AutoComment_Option2 = "#rsSubStageData.Responsibility_AutoComment_Option2#"
						Responsibility_AutoComment_Option3 = "#rsSubStageData.Responsibility_AutoComment_Option3#"
						Responsibility_AutoComment_Option4 = "#rsSubStageData.Responsibility_AutoComment_Option4#"
						Responsibility_forceTextNote = "#rsSubStageData.Responsibility_forceTextNote#"
						Responsibility_miscDetails1 = "#rsSubStageData.Responsibility_miscDetails1#"
						Responsibility_miscDetails2 = "#rsSubStageData.Responsibility_miscDetails2#"
						Responsibility_miscDetails3 = "#rsSubStageData.Responsibility_miscDetails3#"
						Responsibility_miscDetails4 = "#rsSubStageData.Responsibility_miscDetails4#"
						Responsibility_ParentQuestion_Reference = "#rsSubStageData.Responsibility_ParentQuestion_Reference#"
						Responsibility_StandardFile_Number = "#rsSubStageData.Responsibility_StandardFile_Number#"
						Responsibility_StandardFile_UseProofingClient = "#rsSubStageData.Responsibility_StandardFile_UseProofingClient#"
						Responsibility_StandardFile_DetailedFileInfo_Generate="#rsSubStageData.Responsibility_StandardFile_DetailedFileInfo_Generate#"
						Responsibility_StandardFile_DetailedFileInfo_Display="#rsSubStageData.Responsibility_StandardFile_DetailedFileInfo_Display#"
						Responsibility_StandardFile_Display_SmartMedia_Metadata="#rsSubStageData.Responsibility_StandardFile_Display_SmartMedia_Metadata#"
						Responsibility_StandardFile_ValidateUploadAgainstStandard="#rsSubStageData.Responsibility_StandardFile_ValidateUploadAgainstStandard#"
						Responsibility_StandardFile_ValidateUploadAgainstStandard_PreventFinish="#rsSubStageData.Responsibility_StandardFile_ValidateUploadAgainstStandard_PreventFinish#"
						WorkFlowType_UseFDF = "#request.overrideWorkflowUseFDF( rsSubStageData.WorkFlowTypeCode , rsSubStageData.WorkFlowType_UseFDF )#"
						helpText = "#rsSubStageData.Responsibility_helpText#"
						fullWidth = #fullWidth#
						useFieldLock = "#rsSubStageData.QType_useFieldLock#"
						OverrideButtonLabel = "#rsSubStageData.Responsibility_OverrideButtonLabel#"
						OverrideButtonWidth = "#rsSubStageData.Responsibility_OverrideButtonWidth#"
						OverrideButtonStyle = "#rsSubStageData.Responsibility_OverrideButtonStyle#"
						QType_DefaultButtonLabel = "#rsSubStageData.QType_DefaultButtonLabel#"
						QType_DefaultButtonWidth = "#rsSubStageData.QType_DefaultButtonWidth#"
						QType_DefaultButtonStyle = "#rsSubStageData.QType_DefaultButtonStyle#"
						Responsibility_LogAnswer = "#rsSubStageData.Responsibility_LogAnswer#"
						Responsibility_HideNormalStageFinishButton = "#rsSubStageData.Responsibility_HideNormalStageFinishButton#"
					>
					<cfelse>
					</cfif>
			</cfsavecontent>

		<cfcatch>
		<cfdump  var="#cfcatch#" abort="true">
		</cfcatch>
		</cftry>
			
            <cfif FindNoCase("<b/>", responsibilityDescriptionString) eq 0 AND !hiddenByOtherQuestion>
				<cfset ArrayAppend(jsonArray, { "description": responsibilityDescriptionString, "stagecode": rsSubStageData.stagecode, "rolecode": rsSubStageData.rolecode, "groupprioritizationnumber": rsSubStageData.stagerole_groupprioritizationnumber, "answer": Answer, "isThisResponsibilityInputInAciveState": isThisResponsibilityInputInAciveState, "hiddenByOtherQuestion": hiddenByOtherQuestion, "rolecode": rsSubStageData.RoleCode,"StageRole_HasReferencePanel":rsSubStageData.StageRole_HasReferencePanel, "qtypecode": rsSubStageData.Responsibility_QTypeCode, "qtypesubcode": rsSubStageData.Responsibility_QTypeSubCode, "Responsibility_miscDetails4" :rsSubStageData.Responsibility_miscDetails4, "approveSection": approveSection, "rolecontext": rolecontext, "ResponsibilityCode":rsSubStageData.ResponsibilityCode, "iterationNo": request.THIS_currentStageIterationNo,"dropdownDataArray": dropdownDataArray, "required" :rsSubStageData.Responsibility_IsRequired})>

            </cfif>
        </cfloop>

        <!--- Convert the JSON array to a JSON string --->
        <cfset jsonString = SerializeJSON(jsonArray)>
		
		
	    <cfreturn jsonString>
	</cffunction>

	<cffunction  name="getWorkflowSummaryData" access="public" returntype="any">
		<cfargument name="itemSeqNo" type="string">
		<cfargument name="jwtData" type="struct">

        <cfset theWorkflowItemSeqNo = arguments.itemSeqNo>

		<cfquery name="rsParticipantsByStage" datasource="#request.dsns.onei00maindb#">
			SELECT
				T.LibraryID,
				T.ItemSeqNo,
				T.WFS_WorkFlowTypeCode,
				T.WFS_StageCode,
				T.WFS_ForceNoAnnotations_StageCode,
				W.WorkFlowType_AltWFS_CanStageApproveAltMethod,
				W.WorkFlowType_Description,
				W.WorkFlowType_StageApproveWhenOneRoleFinish,
				W.WorkFlowType_StageApproveWhenTwoRoleFinish,
				W.WorkFlowType_StageApproveWhenThreeRoleFinish,
				W.WorkflowType_Grouping,
				SR.WorkFlowTypeCode,
				SR.StageCode,
				SR.RoleCode,
				SR.StageRole_IsStageApprover,
				SR.StageRole_SortNo,
				SR.StageRole_GroupPrioritizationNumber,
				SR.StageRole_Email_Subject,
				SR.StageRole_Email_Instructions,
				SR.StageRole_Email_IncludeReferencePanel,
				SR.StageRole_Email_IncludeCorrections,
				SR.StageRole_Email_Active,
				SR.StageRole_Email_CC_RoleCodes,
				SR.StageRole_Email_Subject_Iteration,
				SR.StageRole_Email_Instructions_Iteration,
				SR.StageRole_Email_IncludeReferencePanel_Iteration,
				SR.StageRole_Email_IncludeCorrections_Iteration,
				SR.StageRole_Email_Active_Iteration,
				SR.StageRole_Email_CC_RoleCodes_Iteration,
				SR.StageRole_Email_Subject_RoleFinish,
				SR.StageRole_Email_Instructions_RoleFinish,
				SR.StageRole_Email_IncludeReferencePanel_RoleFinish,
				SR.StageRole_Email_SendTo_RoleCodes_RoleFinish,
				SR.StageRole_EmailMeFinishSummary,
				SR.StageRole_EmailActionApproval,
				SR.StageRole_DisableOpenEmail,
				SR.StageRole_DontOpenEmailUserJustFinished,
				SR.StageRole_AutoSelectForIteration,
				SR.StageRole_displayTheAbstainOption,
				SR.StageRole_PreventUnfinishInSummary,
				RST.LibraryID AS RST_LibraryID,
				RST.ItemSeqNo AS RST_ItemSeqNo,
				RST.WorkFlowTypeCode AS RST_WorkFlowTypeCode,
				RST.StageCode AS RST_StageCode,
				RST.StageIterationNo AS RST_StageIterationNo,
				RST.RoleCode AS RST_RoleCode,
				RST.RoleSection_DateIn,
				RST.RoleSection_DateOut,
				RST.RoleSection_In_UserID,
				RST.RoleSection_Out_UserID,
				RST.RST_record_dt,
				RST.RST_GroupPrioritizationNumber,
				RST.RST_IsOpen,
				RST.RST_IsSkipping,
				RST.RST_opened,
				RST.RST_opened_dt,
				RST.RST_usernotified,
				DATEDIFF(day, RST.RoleSection_DateIn, getdate()) as DaysRolesOpen,
				S.StageCode AS Stage_StageCode,
				S.Stage_SeqNo,
				S.Stage_DisplaySeqNo,
				S.Stage_Description,
				S.Stage_IsAuxiliary,
				S.Stage_IsInitStage,
				S.Stage_IsFinalApprovalPoint,
				S.Stage_IsDesignArt,
				S.Stage_IsTechnicalProof,
				S.Stage_IsFinalCorrectedProof,
				S.Stage_IsRequiringRoleSectionsPrioritization,
				S.Stage_GroupNumberAtWhichToNotifyObservers,
				S.Stage_Email_RequestApproval_Subject,
				S.Stage_Email_RequestApproval_Subject_Iteration,
				S.Stage_Email_RequestApproval_Body,
				S.Stage_Email_RequestApproval_Body_Iteration,
				S.Stage_Email_RequestApproval_IncludeReferencePanel,
				S.Stage_Email_RequestApproval_IncludeReferencePanel_Iteration,
				S.Stage_Email_RequestApproval_IncludeCorrections,
				S.Stage_Email_RequestApproval_IncludeCorrections_Iteration,
				S.Stage_Email_Approved_Subject,
				S.Stage_Email_Approved_Body,
				S.Stage_Email_Approved_Subject_Iteration,
				S.Stage_Email_Approved_Body_Iteration,
				S.Stage_Email_Approved_IncludeReferencePanel,
				S.Stage_Email_Approved_IncludeCorrections,
				S.Stage_Email_Approved_SendToRoleCodes,
				S.Stage_NewVersionInstructions,
				ST.StageCode AS StageTrack_StageCode,
				ST.Stage_Status,
				ST.Stage_Started,
				ST.Stage_Started_dt,
				ST.Stage_finished,
				ST.Stage_finished_dt,
				ST.Stage_current_iteration,
				ST.Stage_CanBeStageApproved,
				ISNULL(ST.Stage_was_skipped,0) AS Stage_was_skipped,
				ST.Stage_was_skipped_dt,
				ST.Stage_was_skipped_by_userid,
				R.Role_IsInitiator,
				R.Role_IsDesignProvider,
				R.Role_IsPrintingProvider,
				R.Role_IsObserver,
				R.Role_IsMandatory,
				R.Role_IsMandatoryFirstOthersSkipped,
				R.Role_IsWorkflowManager,
				R.Role_IsObserver_NotifyOnlyOnce,
				R.Role_Description
				, LU.FixedMapping_UserID AS UserID,
				LU.FixedMapping_UsergroupID AS UsergroupID,
				LU.FixedMapping_Usergroup_SelectedUserID,
				LU.email_when_others_finish,
				LU.abstain_from_participation,
				LU.abstain_set_dt,
				LU.abstain_set_on_stagecode,
				LU.abstain_set_on_iterationNo,
				LU.abstain_set_by_rolecode,
				LU.abstain_set_by_userid
				,
				LU.FixedMapping_UserID AS FM_UserID,
				LU.FixedMapping_UsergroupID,
				SG.Name,
				SG.Last_Name,
				SG.Last_Name as LastName,
				SG.First_Name,
				SG.First_Name as FirstName,
				SG.email,
				SG.phone,
				SG.phone_area_code,
				SG.Company,
				SG.password,
				SG_user_in.Name AS RoleSection_In_UserName,
				SG_user_in.email AS RoleSection_In_UserEmail,
				SG_user_in.phone AS RoleSection_In_UserPhone,
				SG_user_in.phone_area_code AS RoleSection_In_UserPhone_area_code,
				SG_user_out.Name AS RoleSection_Out_UserName,
				SG_user_out.email AS RoleSection_Out_UserEmail,
				SG_user_out.phone AS RoleSection_Out_UserPhone,
				SG_user_out.phone_area_code AS RoleSection_Out_UserPhone_area_code,
				ISNULL( ISNULL( SG_UgSelUser.Name, UG.UsergroupDescription ), SG.Name ) as allocatedUserUsergroupName
				, UG.UsergroupDescription, UG.Usergroup_WorkflowGroupNotifyEmail,
				SG_UgSelUser.Name AS UgSelUserName,
				SG_UgSelUser.first_Name AS UgSelUserFirstName,
				SG_UgSelUser.last_Name AS UgSelUserLastName,
				SG_UgSelUser.Email AS UgSelUserEmail,
				SG_UgSelUser.phone AS UgSelUserPhone,
				SG_UgSelUser.phone_area_code AS UgSelUserPhone_area_code,
				SG_UgSelUser.company AS UgSelUserCompany
			FROM WFS_Task T
			JOIN WFS_WorkFlowType W 
				ON T.WFS_WorkFlowTypeCode = W.WorkFlowTypeCode
			JOIN WFS_WorkflowType_Stages S 
				ON T.WFS_WorkFlowTypeCode = S.WorkFlowTypeCode 
				AND S.Stage_IsActive = 1
			LEFT JOIN WFS_Item_Stages_Track ST 
				ON ST.LibraryID = T.LibraryID 
				AND ST.ItemSeqNo = T.ItemSeqNo 
				AND ST.WorkFlowTypeCode = S.WorkFlowTypeCode 
				AND ST.StageCode = S.StageCode
			JOIN WFS_WorkflowType_Stage_Role_m2m SR 
				ON SR.WorkFlowTypeCode = S.WorkFlowTypeCode 
				AND SR.StageCode = S.StageCode 
				AND SR.StageRole_IsActive = 1
			LEFT JOIN WFS_Item_Stage_Iteration_RoleSections_Track RST
				ON RST.LibraryID = T.LibraryID
				AND RST.ItemSeqNo = T.ItemSeqNo
				AND RST.WorkFlowTypeCode = SR.WorkFlowTypeCode
				AND RST.StageCode = SR.StageCode
				AND RST.StageIterationNo = ST.Stage_current_iteration
				AND RST.RoleCode = SR.RoleCode
			JOIN WFS_WorkFlowType_Roles R 
				ON SR.WorkFlowTypeCode = R.WorkFlowTypeCode
				AND SR.RoleCode = R.RoleCode
				AND R.Role_IsActive = 1
			JOIN WFS_Item_role2users_FixedMappings LU 
				ON R.WorkFlowTypeCode = LU.WorkFlowTypeCode
				AND R.RoleCode = LU.RoleCode
				AND LU.LibraryID = 35
				AND LU.ItemSeqNo = T.ItemSeqNo
			LEFT JOIN [1i00_SmarterWare]..sg_users SG 
				ON SG.UserID = LU.FixedMapping_UserID
			LEFT JOIN [1i00_SmarterWare]..sg_users SG_user_in 
				ON SG_user_in.UserID = RST.RoleSection_In_UserID
			LEFT JOIN [1i00_SmarterWare]..sg_users SG_user_out 
				ON SG_user_out.UserID = RST.RoleSection_Out_UserID
			LEFT JOIN i00use_LibUsergroups UG 
				ON UG.UsergroupID = LU.FixedMapping_UsergroupID
				AND UG.LibraryID = LU.LibraryID
			LEFT JOIN [1i00_Smarterware]..sg_users SG_UgSelUser 
				ON SG_UgSelUser.userid = LU.FixedMapping_Usergroup_SelectedUserID
				AND LU.FixedMapping_Usergroup_SelectedUserID IS NOT NULL
				AND LU.FixedMapping_Usergroup_SelectedUserID <> ''
			WHERE T.LibraryID=#arguments.jwtData.SESSIONS.LibraryID# AND T.ItemSeqNo=#arguments.itemSeqNo# AND SR.StageRole_IsActive=1
			ORDER BY S.Stage_SeqNo, SR.StageRole_GroupPrioritizationNumber, SR.StageRole_SortNo, SR.RoleCode		
		</cfquery>

        <cfset request.op_libraryid = rsParticipantsByStage.LibraryID>
        <cfset currentstage = rsParticipantsByStage.WFS_StageCode>
        <cfset sumVersAction = "queries">
        <cfinclude template="#request.smartgate#applications/1i00/1i00_WFS_html_summary_versions_actions.inc">
        <cfset sumVersAction = "roleDisplay">

		<cfset request.op_userid = arguments.jwtData.SESSIONS.UserID>

        <cfset jsonArray = []>

		<cfset request.getLibraryContext = APPLICATION.oLibrary.getLibraryContext(LibraryID=rsParticipantsByStage.LibraryID)>
		<Cfset getWFitem = getWFItem(itemSeqNo=arguments.itemSeqNo, jwtData=arguments.jwtData)>
		<cfset request.this_workflow_is_active =
			(getWFitem.Item_is_deleted eq 0)
			and
			(getWFitem.Item_Status lt 2)
			and
			(getWFitem.Item_Status gt -2)
			and
			(getWFitem.Item_Status neq 0)
		>

		<cfset show_print_version = 0>
		<cfset theWorkflowItemSeqNo = arguments.itemSeqNo>
		<cfinclude template="#request.cfmpath#applications/1i00/wfsapi/1i00_WFS_qParticipants.q">


        <cfloop query="rsParticipantsByStage">
			<cfset this_stage_is_active = rsParticipantsByStage.StageCode EQ rsParticipantsByStage.WFS_StageCode and rsParticipantsByStage.Stage_finished eq 0>
			
			<Cfset request.UG_userIsWorkflowAdmin = 1>

			<cfset notFinishedYet=(len(trim(rsParticipantsByStage.RoleSection_DateOut)) eq 0)>
			
			
			<cfset canRemind = getWFItem.SubmitterUserid eq request.op_userid
									or qParticipants.UserID eq request.op_userid
									or request.UG_userIsWorkflowAdmin>

			<cfset theWorkflowItemSeqNo=rsParticipantsByStage.ItemSeqNo>
			<cfset qparam_StageCode=rsParticipantsByStage.StageCode>

			<cfset reqStageCode=rsParticipantsByStage.StageCode>
			<cfset reqDecisionpoint=1>
			<cfset reqIterationNo=rsParticipantsByStage.Stage_current_iteration>
		
			<cfinclude template="#APPLICATION.URI.1i00#/wfsapi/1i00_wfs_qStageData.q">
			<cfset q=qStageData>

			<cfset first_dt="">
			<cfset last_dt="">
			<cfset first_userid="">
			<cfset last_userid="">
			<cfset first_userEmail="">
			<cfset last_userEmail="">
			<cfset first_userName="">
			<cfset last_userName="">
			<cfset first_userCompany="">
			<cfset last_userCompany="">


			<cfset n_due=q.recordcount>
			<cfset n_done=0>

			<cfloop query="q">
				<cfset cycle_dt=q.ResponsibilityValue_Input_dt>
				<cfif cycle_dt neq "">
					<cfset n_done=n_done+1>
					<cfif (first_dt eq "")
						or
						(datediff("s", cycle_dt, first_dt) gt 0)
					>
						<cfset first_dt=cycle_dt>
						<cfset first_userid=q.ResponsibilityValue_Input_UserID>
						<cfset first_userEmail=q.ResponsibilityValue_Input_UserEmail>
						<cfset first_userName=q.ResponsibilityValue_Input_UserName>
						<cfset first_userCompany=q.ResponsibilityValue_Input_UserCompany>
					</cfif>
					<cfif (last_dt eq "")
						or
						(datediff("s",last_dt,cycle_dt) gt 0)
					>
						<cfset last_dt=cycle_dt>
						<cfset last_userid=q.ResponsibilityValue_Input_UserID>
						<cfset last_userEmail=q.ResponsibilityValue_Input_UserEmail>
						<cfset last_userName=q.ResponsibilityValue_Input_UserName>
						<cfset last_userCompany=q.ResponsibilityValue_Input_UserCompany>
					</cfif>
				</cfif>

			</cfloop>

			<cfset appr = structnew()>
			<cfset appr.RoleCode=q.RoleCode>
			<cfset appr.Role_Description=q.Role_Description>
			<cfset appr.UserID=q.UserID>
			<cfset appr.FixedMapping_UsergroupID = q.FixedMapping_UsergroupID>
			<cfset appr.FixedMapping_Usergroup_SelectedUserID = q.FixedMapping_Usergroup_SelectedUserID>
			<cfset appr.UsergroupDescription = q.UsergroupDescription>

			<cfset appr.Name=q.UserName>
			<cfset appr.FirstName=q.UserFirstName>
			<cfset appr.LastName=q.UserLastName>
			<cfset appr.UgSelUserName=q.UgSelUserName>
			<cfset appr.UgSelUserFirstName=q.UgSelUserFirstName>
			<cfset appr.UgSelUserLastName=q.UgSelUserLastName>

			<cfset appr.Email=q.UserEmail>
			<cfset appr.phone=q.UserPhone>
			<cfset appr.phone_area_code=q.UserPhone_area_code>
			<cfset appr.Company=q.UserCompany>

			<cfset appr.UgSelUserEmail=q.UgSelUserEmail>
			<cfset appr.UgSelUserphone=q.UgSelUserPhone>
			<cfset appr.UgSelUserphone_area_code=q.UgSelUserPhone_area_code>
			<cfset appr.UgSelUserCompany=q.UgSelUserCompany>

			<cfset appr.RST_RoleCode="">
			<cfif first_dt neq "">
				<cfset appr.RST_RoleCode=appr.RoleCode>
			</cfif>

			<cfset appr.RoleSection_DateIn=first_dt>
			<cfset appr.RoleSection_DateOut=last_dt>

			<cfset appr.RoleSection_In_UserID=first_UserID>
			<cfset appr.RoleSection_Out_UserID=last_UserID>

			<cfset appr.RoleSection_In_UserEmail=first_UserEmail>
			<cfset appr.RoleSection_Out_UserEmail=last_UserEmail>

			<cfset appr.RoleSection_In_UserName=first_UserName>
			<cfset appr.RoleSection_Out_UserName=last_UserName>

			<cfset appr.RoleSection_In_UserCompany=first_UserCompany>
			<cfset appr.RoleSection_Out_UserCompany=last_UserCompany>

			<cfset appr.hasApproved=(q.Stage_finished eq 1)>
			<cfset appr.hasApproved_dt=q.Stage_finished_dt>
					
			<cfsavecontent variable="ApproverJson">
				<cfoutput>
					<cfset displayUser = "#appr.FirstName# #appr.LastName#">
					<cfif appr.hasApproved>
						<cfset apprStatus = "<span style='color:green;' title='#dateFormat(appr.hasApproved_dt, "d mmm yy")# at #timeFormat(appr.hasApproved_dt, "h:mm tt")#'>APPROVED on #dateFormat(appr.hasApproved_dt, "d mmm yy")#</span>">
					<cfelseif this_stage_is_active>
						<cfset apprStatus = "<span style='color:##800000;'>Pending Approval</span>">
					<cfelse>
						<cfset apprStatus = "Not Started">
					</cfif>
					{
						"apprRole": "#appr.Role_Description#",
						"apprUser": "#displayUser#",
						"apprStatus": "#apprStatus#"
					}
				</cfoutput>
			</cfsavecontent>

            <cfset this_stage_future = rsParticipantsByStage.StageCode gt rsParticipantsByStage.WFS_StageCode>
        
            <cfsavecontent  variable="StageVersion">
                <cfinclude template="#request.smartgate#applications/1i00/1i00_WFS_html_summary_versions_actions.inc"> 
            </cfsavecontent>

            <cfsavecontent  variable="StageStarted">
                <cfoutput>
            
                    <cfif len(trim(rsParticipantsByStage.StageTrack_StageCode)) eq 0>
                        Not Yet Started
                    <cfelse>
                        <cfif rsParticipantsByStage.Stage_Started eq 0>
                            Not Yet Started
                        <cfelse>
                            #dateformat(rsParticipantsByStage.Stage_Started_dt,"dd mmm yyyy")#
                        </cfif>
                    </cfif>
                </cfoutput>
            </cfsavecontent>

			<cfsavecontent  variable="StageEnd">
				<cfoutput>
					<cfif len(trim(rsParticipantsByStage.StageTrack_StageCode)) eq 0>
						&nbsp;
					<cfelse>
						<cfif rsParticipantsByStage.Stage_was_skipped eq 1>
							<cfquery name="getSkippedBy" datasource="#request.dsns.onei00maindb#">
								SELECT 	name
								FROM 	[1i00_SmarterWare]..sg_users
								WHERE 	userid = '#rsParticipantsByStage.Stage_was_skipped_by_userid#'
							</CFQUERY>
							<span style="color:red;">Stage Skipped<br>#getSkippedBy.name#<br>
							#DateFormat(rsParticipantsByStage.Stage_was_skipped_dt,"dd mmm yyyy")#&nbsp;at&nbsp;#TimeFormat(rsParticipantsByStage.Stage_was_skipped_dt, "HH:mm")#</span>
						<cfelseif rsParticipantsByStage.Stage_finished eq 0>
							Not Yet Finished
						<cfelse>
							#dateformat(rsParticipantsByStage.Stage_finished_dt,"dd mmm yyyy")#
						</cfif>
					</cfif>		
				</cfoutput>	
			</cfsavecontent>
			<cfif canRemind and this_stage_is_active and isDefined("notFinishedYet") and notFinishedYet and request.this_workflow_is_active and show_print_version eq 0>
				<cfset isReminder = 1>
			<cfelse>
				<cfset isReminder = 0>
			</cfif>

			<cfset displayUser="#rsParticipantsByStage.first_Name# #rsParticipantsByStage.last_Name#">
			<cfset displayUser=DisplayUser &" - ("&rsParticipantsByStage.Company&") ">  

			<cfset remind_url="1i00_wfs_send_reminder_emails.cfm?theWorkflowItemSeqNo=#theWorkflowItemSeqNo#&stageid=#rsParticipantsByStage.StageCode#&act=role&roleid=#rsParticipantsByStage.RoleCode#">        

            <cfset ArrayAppend(jsonArray, { "StageDesc": rsParticipantsByStage.Stage_Description, "StageStarted": StageStarted, "StageEnd": StageEnd, "RoleDesc": rsParticipantsByStage.Role_Description, "Role_IsDesignProvider": rsParticipantsByStage.Role_IsDesignProvider, "Role_IsPrintingProvider": rsParticipantsByStage.Role_IsPrintingProvider, "displayUser": displayUser, "StageVersion":StageVersion, "ApproverJson":ApproverJson, "isReminder": isReminder,"this_stage_is_active" : this_stage_is_active,"remind_url" : remind_url })>
            
        </cfloop>
        <cfset jsonString = SerializeJSON(jsonArray)>
        <Cfreturn jsonString>		
	</cffunction>

	<cffunction  name="getJobFlowLogs" access="public" returntype="array">
		<cfargument name="itemSeqNo" type="string">
		<cfargument name="jwtData" type="struct">
		
		<cfquery name="arr_workflowlogs" returntype="array" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">

			SELECT
				C.Comment_SeqNo,
				C.Comment_Input_RoleCode,
				R.Role_Description as Comment_Input_RoleDesc,
				C.Comment_Input_UserID,
				C.Comment_Input_dt,
				C.Comment_Input_Roles,
				C.Comment_Text,
				C.Comment_HiddenExtraText_InteractOnly,
				C.StageIterationNo,
				C.StageCode,
				ST.Stage_Description,
				SG.Name AS UserName,
				SG.First_Name AS UserFirstName,
				SG.Last_Name AS UserLastName,
				SG.Email AS UserEmail
			FROM [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Comments C 
			LEFT JOIN [1i00_SmarterWare]..sg_users SG ON SG.UserID=C.Comment_Input_UserID
			LEFT JOIN [1i00_Central]..WFS_WorkFlowType_Stages ST ON ST.WorkFlowTypeCode = C.WorkFlowTypeCode AND ST.StageCode = C.StageCode
			LEFT JOIN [1i00_Central]..WFS_WorkFlowType_Roles R ON R.WorkFlowTypeCode = C.WorkFlowTypeCode AND R.RoleCode = C.Comment_Input_RoleCode
			WHERE LibraryID = #arguments.jwtData.SESSIONS.libraryid#
			AND ItemSeqNo = #arguments.itemSeqNo#
			ORDER BY C.StageCode ASC, C.Comment_Input_dt DESC		
		
		</cfquery>
		
		<cfreturn arr_workflowlogs>
	</cffunction>

	
	<cffunction  name="getJobFlowDetail" access="public" returntype="array">
		<cfargument name="itemSeqNo" type="string">
		<cfargument name="jwtData" type="struct">
		
		<cfquery name="arr_workflowDetail" returntype="array" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">

			SELECT	
				V.LibraryID, V.ItemSeqNo, V.Item_WFS, V.Item_Status, V.SubmitterUserid, V.ManagerUserid, V.UploaderUserid, V.Item_dt_submitted, V.ApproverUserid, V.Item_Resource_RUID, V.Item_dt_released, V.Item_dt_suspended,
				V.Item_dt_approved, V.Item_dt_rejected, V.Item_dt_cancelled, V.Item_dt_cancelled_by_userid, V.Item_is_archived, V.Item_is_deleted, V.Item_dt_archived, V.Item_dt_deleted, V.Item_archived_by_userid, V.Item_deleted_by_userid,
				V.Item_DecisionNote, V.Item_prev_ItemSeqNo, V.Item_next_ItemSeqNo, V.Item_MarkupLastChangeNo, V.Item_MarkupLastGeneratedChangeNo, V.Item_MarkupIsActive, V.Item_MarkupActive_Type, V.Item_MarkupActive_OrigFile_dt_stamp,
				V.Item_MarkupBy_dt_started, V.dt_now, V.Item_MarkupBy_warnings, V.Item_MarkupBy_UserID, V.Item_MarkupBy_cfid, V.Item_MarkupBy_cftoken, V.Item_MarkupBy_usermachine, V.Item_MarkupBy_remote_addr, V.Item_MarkupBy_Simultaneous,
				V.Item_MarkupBy_SessionID, V.Item_Markup_WF_Current_RTImarkupID, V.Item_Markup_PROOF_Current_RTImarkupID,
				FORMAT(V.Item_wf_StartDate, 'dd MMM yyyy') Item_wf_StartDate, FORMAT(V.Item_wf_IntermediateDate, 'dd MMM yyyy') Item_wf_IntermediateDate, FORMAT(V.Item_wf_DueDate, 'dd MMM yyyy') Item_wf_DueDate, V.Item_wf_Objective, V.Item_wf_TextNote, V.Item_wf_Priority, V.Item_wf_LockedNoComments, V.Item_wf_SignoffRequested,
				V.Item_wf_client_reference, V.Item_wf_Final_Approver_Comments, V.Item_wf_Final_Approver_Last_Viewed, V.Item_FinishedArt_RUID, V.Item_CCAID, V.Item_finished_file_resource_type,
				V.Item_ItemCode, V.Item_Version, V.Item_ClientCodeA, V.Item_ClientCodeB, V.Item_ClientCodeC, V.WorkFlowType_Description, V.WorkFlowType_FinalArt_ApprovalUsergroupID, V.WorkFlowType_WFSSpecificType, V.WorkFlowType_AlternateWFSUsesProof,
				V.WorkFlowType_AltWFS_RoleLabel, V.WorkFlowType_AltWFS_CreatorIsManager, V.WorkFlowType_UseRtiAnnotations, V.WorkFlowType_UseFDF, V.WorkFlowType_UseVProof, V.WorkFlowType_ShowOtherRolesLink, V.WorkFlowType_UseFileUploadOptionalPreview,
				V.WorkFlowType_AltWFS_UseQuoteGroup, V.WorkFlowType_AltWFS_QuoteGroupLabel, V.WorkFlowType_AltWFS_UploadBrief, V.WorkFlowType_AltWFS_TypeInsteadOfFirstFile, V.WorkFlowType_AltWFS_SepGroupPerRole,
				V.WorkFlowType_StageApproveWhenOneRoleFinish, V.WorkFlowType_StageApproveWhenTwoRoleFinish, V.WorkFlowType_StageApproveWhenThreeRoleFinish, V.WorkFlowType_DueDateLabel, V.WorkFlowType_ApprovalRoleLabel, V.WorkFlowType_IsActive, V.WorkFlowType_UsePostActionNotification,
				V.WorkflowType_ClientCodeALabel, V.WorkflowType_ClientCodeBLabel, V.WorkflowType_ClientCodeCLabel,
				V.WorkflowType_ClientCodeACharType, V.WorkflowType_ClientCodeALengthMin, V.WorkflowType_ClientCodeALengthMax, V.WorkflowType_ClientCodeBCharType,
				V.WorkflowType_ClientCodeBLengthMin, V.WorkflowType_ClientCodeBLengthMax, V.WorkflowType_ClientCodeCCharType,
				V.WorkflowType_ClientCodeCLengthMin, V.WorkflowType_ClientCodeCLengthMax, V.WFS_Designer_Company, V.WFS_Designer_ContactPerson, V.WFS_Printer_Company, V.WFS_Printer_ContactPerson,
				V.WFS_Artwork_hasBeenSubmtted, V.WFS_Artwork_hasBeenSubmtted_dt, V.WFS_Artwork_hasBeenSubmtted_userid, V.WFS_Artwork_ID, V.WFS_Proof_hasBeenSubmtted, V.WFS_Proof_hasBeenSubmtted_dt, V.WFS_Proof_hasBeenSubmtted_userid,
				V.WFS_Proofing_ID, V.WFS_WorkFlowTypeCode, V.WFS_DesignForPrepress_Filename_Saved, V.WFS_DesignForPrepress_Filename_Original, V.WFS_DesignForPrepress_PDF_Filename_Saved, V.WFS_DesignForPrepress_PDF_Filename_Original,
				V.WFS_QuoteGroup, V.WFS_UploadBrief_Filename_Saved, V.WFS_UploadBrief_Filename_Original, V.WFS_RoleFinish_EmailStageApprover, V.Proofing_OrigFileName, V.Proofing_WorkFileName, V.Proofing_UploadRef, V.Proofing_Status,
				V.ApproverName, V.ApproverEmail, V.ApproverPhone, V.SubmitterName, V.SubmitterEmail, V.SubmitterPhone, V.Submitter_CCAID,
				V.ManagerName, V.ManagerEmail, V.ManagerPhone, V.ManagerCompany, V.ManagerPhoneAreaCode, V.ManageraddressFloorLevel, V.ManagerAddress, V.ManagerState, V.ManagerPostcode, V.Manager_CCAID,
				V.OriginalSubmitterName, V.OriginalSubmitterEmail, V.OriginalSubmitterPhone, V.UploaderName, V.UploaderEmail, V.UploaderPhone,
				V.RDescription, V.RCodeInLibrary, V.priorRevisionOrder, V.priorRevisionSeriesID, V.RDeleted, V.Bin3_Status, V.Bin3_OrigFileName,
				V.Item_fastReview_resourceTypeID, V.Item_fastReview_usergroupID, V.Item_alternateWFS_typeID, V.Item_DAM_Parent_RUID,
				
				V.RTcodename, V.UsergroupDescription, V.alternateWFSType_label, V.LibSpecific_FinalArt_ApprovalUsergroupID,
				W.WorkFlowType_UseRemoteDirector,
				(
					SELECT 		Item_wf_DueTime
					FROM		[1i00_Central]..i00wf_Item WF
					WHERE		WF.LibraryID = #arguments.jwtData.SESSIONS.LibraryID#
					AND 		WF.ItemSeqNo = #arguments.itemSeqNo#

				) DueTime,
				(
					SELECT 		WF.Item_OnHold
					FROM		[1i00_Central]..i00wf_Item WF
					WHERE		WF.LibraryID = #arguments.jwtData.SESSIONS.LibraryID#
					AND 		WF.ItemSeqNo = #arguments.itemSeqNo#

				) OnHold

			FROM V_WF_GetWFItem V
			LEFT OUTER JOIN [1i00_Central].dbo.WFS_WorkFlowType W ON V.WFS_WorkFlowTypeCode = W.WorkFlowTypeCode
			WHERE LibraryID = #arguments.jwtData.SESSIONS.libraryid# 
			AND	V.ItemSeqNo	= #arguments.itemSeqNo#				
		
		</cfquery>
		
		<cfreturn arr_workflowDetail>
	</cffunction>

	<cffunction  name="getWorkFlowAllRoles" access="public" returntype="array">
		<cfargument name="itemSeqNo" type="string" required="true">
		<cfargument name="jwtData" type="struct" required="true">
		
		<cfquery name="arr_getWorkFlowAllRoles" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#" returntype="array">
			SELECT 
				CASE 
					WHEN 
						(SubmitterUserid = '#arguments.jwtData.sessions.userid#' AND ISNULL(FixedMapping_UsergroupID,'') = '')
						OR
						(x.UserID = '#arguments.jwtData.sessions.userid#' AND ISNULL(x.FixedMapping_UsergroupID,'') = '')
					THEN 1
					ELSE 0 END AS ShowAppointBtn
				,ISNULL(
					CASE
						WHEN (SubmitterUserid = '#arguments.jwtData.sessions.userid#' OR UsergroupMembersList = 1)
							AND x.name <> '' 
							AND (x.Role_IsWorkflowManager = 0 OR SubmitterUserid <> '#arguments.jwtData.sessions.userid#')
						THEN 'Change'
						WHEN (SubmitterUserid = '#arguments.jwtData.sessions.userid#' OR UsergroupMembersList = 1)
							AND ISNULL(x.name, '') = ''
						THEN 'Assign'
						ELSE 'Appoint'
					END,
					'Appoint'
				) AS BtnText
				,x.*
			FROM
			(
				SELECT
					T.WFS_WorkFlowTypeCode,
					T.WFS_StageCode,
					W.WorkflowtypeCode,
					W.Workflowtype_Description,
					W.Workflowtype_UsageNote,
					R.Role_Description,
					R.RoleCode,
					R.Role_IsInitiator,
					R.Role_IsDesignProvider,
					R.Role_IsPrintingProvider,
					R.Role_IsObserver,
					R.Role_IsObserver_NotifyOnlyOnce,
					R.Role_IsMandatory,
					R.Role_IsMandatoryAfterStart,
					R.Role_IsWorkflowManager,
					R.Role_AssignmentPrioritizationNumber,
					R.Role_IsExternalRole,
					R.Role_SortNo,
					R.Role_PreApproveRestricted,
					R.Role_NoChangeUserInParticipants,
					R.Role_MirrorOtherRole,
					R.Role_NoAllocateOnCreate,
					R.Role_FinishedArt_StdClsRole,
					LU.FixedMapping_UserID AS UserID,
					LU.FixedMapping_UsergroupID,
					LU.FixedMapping_Usergroup_SelectedUserID,
					LU.FixedMapping_IsGroupParticipation,
					LU.email_when_others_finish,
					LU.abstain_from_participation,
					LU.abstain_set_dt,
					LU.abstain_set_on_stagecode,
					LU.abstain_set_by_rolecode,
					LU.abstain_set_by_userid,
					LU.ToBeAssigned,
					SG.Name,
					SG.last_Name,
					SG.first_Name,
					SG.email,
					SG.phone_area_code,
					SG.phone,
					SG.company,
					SG.addressFloorLevel,
					SG.address,
					SG.suburb,
					SG.state,
					SG.country,
					SG.postcode,
					UG.UsergroupDescription, UG.Usergroup_WorkflowGroupNotifyEmail,
					UG_SelUser.Name AS UG_SelUser_Name,
					UG_SelUser.first_Name AS UG_SelUser_FirstName,
					UG_SelUser.last_Name AS UG_SelUser_LastName,
					UG_SelUser.email AS UG_SelUser_email,
					UG_SelUser.phone_area_code AS UG_SelUser_phone_area_code,
					UG_SelUser.phone AS UG_SelUser_phone,
					UG_SelUser.company AS UG_SelUser_company,
					UG_SelUser.Name AS UGSelUserName,
					UG_SelUser.first_Name AS UGSelUserFirstName,
					UG_SelUser.last_Name AS UGSelUserLastName,
					UG_SelUser.email AS UGSelUseremail,
					UG_SelUser.phone_area_code AS UGSelUserPhone_Area_Code,
					UG_SelUser.phone AS UGSelUserphone,
					UG_SelUser.company AS UGSelUsercompany,
					(
						SELECT V.SubmitterUserid
						FROM [1i00_Library_Imperic]..V_WF_GetWFItem V
						WHERE V.LibraryID = T.LibraryID
						AND V.ItemSeqNo = T.ItemSeqNo
					) SubmitterUserid,
					(
						SELECT MAX(1*UG.Usergroup_Workflow_HasAdminChangeParticipants) 
						FROM	[1i00_Central]..i00use_LibCustUsergroup_m2m AS M2M
						JOIN [1i00_Central]..i00use_LibUsergroups AS UG 
							ON M2M.UsergroupID=UG.UsergroupID
								AND M2M.LibraryID=UG.LibraryID
						WHERE	M2M.CustomerID = '#arguments.jwtData.sessions.userid#'
						AND		M2M.LibraryID = T.LibraryID
					) AS UsergroupMembersList
				FROM [1i00_Central]..WFS_Task AS T
				JOIN [1i00_Central]..WFS_WorkFlowType AS W ON W.WorkFlowTypeCode = T.WFS_WorkFlowTypeCode
				JOIN [1i00_Central]..WFS_Workflowtype_Roles AS R ON R.WorkflowTypeCode = W.WorkflowTypeCode AND (R.Role_IsActive=1)
				LEFT JOIN [1i00_Central]..WFS_Item_role2users_FixedMappings AS LU ON R.WorkFlowTypeCode = LU.WorkFlowTypeCode AND R.RoleCode = LU.RoleCode 
					AND LU.LibraryID = '#arguments.jwtData.sessions.LibraryID#' AND LU.ItemSeqNo = T.ItemSeqNo
				LEFT JOIN [1i00_SmarterWare]..sg_users AS SG ON SG.UserID = LU.FixedMapping_UserID
				LEFT JOIN [1i00_Central]..i00use_LibUsergroups AS UG ON UG.UsergroupID = LU.FixedMapping_UsergroupID AND UG.LibraryID = LU.LibraryID
				LEFT JOIN [1i00_SmarterWare]..sg_users AS UG_SelUser ON uG_SelUser.UserID = LU.FixedMapping_Usergroup_SelectedUserID
				WHERE T.ItemSeqNo = '#arguments.itemSeqNo#'
				AND T.LibraryID = '#arguments.jwtData.sessions.LibraryID#'
			)x
			ORDER BY x.Role_SortNo
		
		</cfquery>
		
		<cfreturn arr_getWorkFlowAllRoles>
	</cffunction>


	<cffunction  name="getWFItem" access="public" returntype="any" output="true">
		<cfargument name="itemSeqNo" type="string" required="true">
		<cfargument name="jwtData" type="struct" required="true">
		<cfargument  name="stageCode" type="string" required="false" default="">
		
		<cfquery name="getWFitem" datasource="#arguments.jwtData.SESSIONS.library_context.LibraryODBCsource#">
			SELECT 
			<Cfif len(arguments.stageCode) gt 0>
				S.StageCode,S.Stage_Description,S.Stage_SeqNo,
			</Cfif>
			V.LibraryID, V.ItemSeqNo, V.Item_WFS, V.Item_Status, V.SubmitterUserid, V.ManagerUserid, V.UploaderUserid, V.Item_dt_submitted, V.ApproverUserid, V.Item_Resource_RUID, V.Item_dt_released, V.Item_dt_suspended,
			V.Item_dt_approved, V.Item_dt_rejected, V.Item_dt_cancelled, V.Item_dt_cancelled_by_userid, V.Item_is_archived, V.Item_is_deleted, V.Item_dt_archived, V.Item_dt_deleted, V.Item_archived_by_userid, V.Item_deleted_by_userid,
			V.Item_DecisionNote, V.Item_prev_ItemSeqNo, V.Item_next_ItemSeqNo, V.Item_MarkupLastChangeNo, V.Item_MarkupLastGeneratedChangeNo, V.Item_MarkupIsActive, V.Item_MarkupActive_Type, V.Item_MarkupActive_OrigFile_dt_stamp,
			V.Item_MarkupBy_dt_started, V.dt_now, V.Item_MarkupBy_warnings, V.Item_MarkupBy_UserID, V.Item_MarkupBy_cfid, V.Item_MarkupBy_cftoken, V.Item_MarkupBy_usermachine, V.Item_MarkupBy_remote_addr, V.Item_MarkupBy_Simultaneous,
			V.Item_MarkupBy_SessionID, V.Item_Markup_WF_Current_RTImarkupID, V.Item_Markup_PROOF_Current_RTImarkupID,
			FORMAT(V.Item_wf_StartDate, 'dd MMM yyyy') Item_wf_StartDate, FORMAT(V.Item_wf_IntermediateDate, 'dd MMM yyyy') Item_wf_IntermediateDate, FORMAT(V.Item_wf_DueDate, 'dd MMM yyyy') Item_wf_DueDate, V.Item_wf_Objective, V.Item_wf_TextNote, V.Item_wf_Priority, V.Item_wf_LockedNoComments, V.Item_wf_SignoffRequested,
			V.Item_wf_client_reference, V.Item_wf_Final_Approver_Comments, V.Item_wf_Final_Approver_Last_Viewed, V.Item_FinishedArt_RUID, V.Item_CCAID, V.Item_finished_file_resource_type,
			V.Item_ItemCode, V.Item_Version, V.Item_ClientCodeA, V.Item_ClientCodeB, V.Item_ClientCodeC, V.WorkFlowType_Description, V.WorkFlowType_FinalArt_ApprovalUsergroupID, V.WorkFlowType_WFSSpecificType, V.WorkFlowType_AlternateWFSUsesProof,
			V.WorkFlowType_AltWFS_RoleLabel, V.WorkFlowType_AltWFS_CreatorIsManager, V.WorkFlowType_UseRtiAnnotations, V.WorkFlowType_UseFDF, V.WorkFlowType_UseVProof, V.WorkFlowType_ShowOtherRolesLink, V.WorkFlowType_UseFileUploadOptionalPreview,
			V.WorkFlowType_AltWFS_UseQuoteGroup, V.WorkFlowType_AltWFS_QuoteGroupLabel, V.WorkFlowType_AltWFS_UploadBrief, V.WorkFlowType_AltWFS_TypeInsteadOfFirstFile, V.WorkFlowType_AltWFS_SepGroupPerRole,
			V.WorkFlowType_StageApproveWhenOneRoleFinish, V.WorkFlowType_StageApproveWhenTwoRoleFinish, V.WorkFlowType_StageApproveWhenThreeRoleFinish, V.WorkFlowType_DueDateLabel, V.WorkFlowType_ApprovalRoleLabel, V.WorkFlowType_IsActive, V.WorkFlowType_UsePostActionNotification,
			V.WorkflowType_ClientCodeALabel, V.WorkflowType_ClientCodeBLabel, V.WorkflowType_ClientCodeCLabel,
			V.WorkflowType_ClientCodeACharType, V.WorkflowType_ClientCodeALengthMin, V.WorkflowType_ClientCodeALengthMax, V.WorkflowType_ClientCodeBCharType,
			V.WorkflowType_ClientCodeBLengthMin, V.WorkflowType_ClientCodeBLengthMax, V.WorkflowType_ClientCodeCCharType,
			V.WorkflowType_ClientCodeCLengthMin, V.WorkflowType_ClientCodeCLengthMax, V.WFS_Designer_Company, V.WFS_Designer_ContactPerson, V.WFS_Printer_Company, V.WFS_Printer_ContactPerson,
			V.WFS_Artwork_hasBeenSubmtted, V.WFS_Artwork_hasBeenSubmtted_dt, V.WFS_Artwork_hasBeenSubmtted_userid, V.WFS_Artwork_ID, V.WFS_Proof_hasBeenSubmtted, V.WFS_Proof_hasBeenSubmtted_dt, V.WFS_Proof_hasBeenSubmtted_userid,
			V.WFS_Proofing_ID, V.WFS_WorkFlowTypeCode, V.WFS_DesignForPrepress_Filename_Saved, V.WFS_DesignForPrepress_Filename_Original, V.WFS_DesignForPrepress_PDF_Filename_Saved, V.WFS_DesignForPrepress_PDF_Filename_Original,
			V.WFS_QuoteGroup, V.WFS_UploadBrief_Filename_Saved, V.WFS_UploadBrief_Filename_Original, V.WFS_RoleFinish_EmailStageApprover, V.Proofing_OrigFileName, V.Proofing_WorkFileName, V.Proofing_UploadRef, V.Proofing_Status,
			V.ApproverName, V.ApproverEmail, V.ApproverPhone, V.SubmitterName, V.SubmitterEmail, V.SubmitterPhone, V.Submitter_CCAID,
			V.ManagerName, V.ManagerEmail, V.ManagerPhone, V.ManagerCompany, V.ManagerPhoneAreaCode, V.ManageraddressFloorLevel, V.ManagerAddress, V.ManagerState, V.ManagerPostcode, V.Manager_CCAID,
			V.OriginalSubmitterName, V.OriginalSubmitterEmail, V.OriginalSubmitterPhone, V.UploaderName, V.UploaderEmail, V.UploaderPhone,
			V.RDescription, V.RCodeInLibrary, V.priorRevisionOrder, V.priorRevisionSeriesID, V.RDeleted, V.Bin3_Status, V.Bin3_OrigFileName,
			V.Item_fastReview_resourceTypeID, V.Item_fastReview_usergroupID, V.Item_alternateWFS_typeID, V.Item_DAM_Parent_RUID,
			V.RTcodename, V.UsergroupDescription, V.alternateWFSType_label, V.LibSpecific_FinalArt_ApprovalUsergroupID,
			W.WorkFlowType_UseRemoteDirector
			FROM V_WF_GetWFItem V
			LEFT OUTER JOIN [1i00_Central].dbo.WFS_WorkFlowType W ON V.WFS_WorkFlowTypeCode = W.WorkFlowTypeCode
			<Cfif len(arguments.stageCode) gt 0>
				JOIN [1i00_Central].dbo.WFS_WorkflowType_Stages S ON S.WorkflowtypeCode=V.WFS_WorkFlowTypeCode AND S.StageCode=#arguments.stageCode#
			</Cfif>
			WHERE LibraryID = '#arguments.jwtData.SESSIONS.LibraryID#'
			AND ItemSeqNo = '#arguments.itemSeqNo#'
		</cfquery>

		<cfreturn getWFitem>			
	</cffunction>

	<cffunction  name="getParticipantsDropDownData" access="public" returntype="any" output="true">
		<cfargument name="itemSeqNo" type="string" required="true">
		<cfargument name="jwtData" type="struct" required="true">
		<cfargument  name="RoleCode" type="any" required="true">
		

		<Cfset getWFitem = getWFItem(itemSeqNo=arguments.itemSeqNo, jwtData=arguments.jwtData)>
		<Cfset request.THIS_WFS_ID = getWFitem.ItemSeqNo>
		
		<cfset request.THIS_hasBeenLocated = true>

		<cfset request.op_libraryid = getWFitem.LibraryID>

		<cfset request.getLibraryContext = APPLICATION.oLibrary.getLibraryContext(LibraryID=arguments.jwtData.SESSIONS.LibraryID)>
		
		<cfset request.THIS_WorkflowtypeCode = getWFitem.WFS_WorkFlowTypeCode>
		
		<cfset RolesUsers_Assign_Style= request.getLibraryContext.Library_WFS_RolesUsersStyle>
		
		<cfset ParticipantsDropDownData = StructNew()>
		
		<cfinclude template="#request.cfmroot#smartgate/applications/1i00/1i00_WFS_qAllUsers.q">

		<cfif getWFitem.WorkFlowType_WFSSpecificType eq "alternateWFS" and getWFitem.WorkFlowType_AltWFS_SepGroupPerRole eq 0>
			<cfset workflowUsergroup = getWFitem.Item_fastReview_usergroupID>

			<!--- filter by usergroup selected or in staff usergroup --->
			<cfquery name="getUsersInUserGroup" datasource="#request.dsns.onei00maindb#">
				SELECT		M2M.CustomerID
				FROM 		i00use_LibCustUsergroup_m2m AS M2M
									INNER JOIN i00use_LibUsergroups AS UG  ON UG.UsergroupID = M2M.UsergroupID
																									AND UG.LibraryID = M2M.LibraryID
				WHERE		M2M.LibraryID=#request.op_libraryid#
				AND				(M2M.UsergroupID = '#workflowUsergroup#'
									OR UG.UsergroupWorkflowStaff = 1)
			</cfquery>

			<cfset request.usersFilter = StructNew()>
			<cfloop query="getUsersInUserGroup">
				<cfif not StructKeyExists(request.usersFilter, CustomerID)>
					<cfset temp = StructInsert(request.usersFilter, CustomerID, 1)>
				</cfif>
			</cfloop>

			<cfinclude template="#request.cfmroot#smartgate/applications/1i00/1i00_WFS_qAllUsers.q">
			<cfset q=qAllUsers>


			<Cfset isGroupParticipation = 0>
		
		<cfelse>
			<cfset getAllowedRoleCode = arguments.RoleCode>

			<cfif RolesUsers_Assign_Style eq 0>
				<cfset q=qAllUsers>
			<cfelse>
				<cfmodule template="#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
					ItemID="#arguments.itemSeqNo#"
					pRole="#getAllowedRoleCode#"
					pUser=""
					call="getAllowedRolesUsersQuery"
					
					var="q"
				>
			</cfif>
			
			<cfmodule template="#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
				ItemID="0"
				pWorkflowType="#request.THIS_WorkflowtypeCode#"
				pRole="#getAllowedRoleCode#"
				pUsergroup=""
				call="getAllowedRolesUsergroupsQuery"
				var="qAllowedRolesUsergroups"
			>
			
			<cfif qAllowedRolesUsergroups.recordCount gt 0>
				<cfset isGroupParticipation = 1>
				<cfset ParticipantsDropDownData.groups = arrayNew(1)>
				<cfloop query="qAllowedRolesUsergroups">
						
					<cfinvoke component="#request.cfc_dot_notation_path#1i00_cfc_get_usergroup_data"
						method="getUsersDetails"
						usergroupID = "#qAllowedRolesUsergroups.UsergroupID#"
						returnVariable = "usergroupUsersDetails"
					>
					
					<cfset groupData = StructNew()>
					<cfset groupData.UsergroupDescription = qAllowedRolesUsergroups.UsergroupDescription>
					<cfset groupData.UsergroupID = "usergroup_" & qAllowedRolesUsergroups.UsergroupID>
					<Cfset groupData.usergroupUsersDetails = usergroupUsersDetails>
					<cfset ArrayAppend(ParticipantsDropDownData.groups, groupData)>
				</cfloop>
			<cfelse>
				<cfset isGroupParticipation = 0>
			</cfif>
		</cfif>

		<!--- Initialize arrays for individual users and groups --->
		<cfset ParticipantsDropDownData.individualUser = arrayNew(1)>
		

		<!--- Append data from q to ParticipantsDropDownData.individualUser --->
		<cfloop query="q">
			<cfset participant = StructNew()>
			<cfset participant.fullName = q.first_name & " " & q.last_name>
			<cfset participant.UserID = q.UserID>
			<cfset participant.Company = q.Company>
			<cfset ArrayAppend(ParticipantsDropDownData.individualUser, participant)>
		</cfloop>
		
		<cfreturn SerializeJSON(ParticipantsDropDownData)>
	</cffunction> 

	<cffunction  name="updaterolecodeuser" access="public" returntype="any" hint="get participants drop down data">
		<cfargument name="jwtData" type="any" required="true" hint="itemSeqNo to get workflows for">
		<cfargument name="itemSeqNo" type="any" required="true" hint="itemSeqNo to get workflows for">
		<cfargument name="RoleCode" type="any" required="true" hint="itemSeqNo to get workflows for">
		<cfargument name="newUserID" type="any" required="true" hint="itemSeqNo to get workflows for">
		<cfargument name="newUsergroupUserID" type="any" required="false" hint="itemSeqNo to get workflows for" default="">
		<cfargument name="ru_selecting_provider" type="any" required="false" hint="itemSeqNo to get workflows for" default="">
		<cfargument name="stageCode" type="any" required="false" hint="itemSeqNo to get workflows for" default="">

		<Cfset getWFitem = getWFItem(itemSeqNo=arguments.itemSeqNo, jwtData=arguments.jwtData, stageCode=arguments.stageCode)>
		
		<Cfset request.THIS_WFS_ID = getWFitem.ItemSeqNo>
		
		<cfset request.THIS_hasBeenLocated = true>

		<cfset request.op_libraryid = getWFitem.LibraryID>

		<cfset REQUEST.getLibraryContext = APPLICATION.oLibrary.getLibraryContext(LibraryID=request.op_libraryid)>
		
		<cfset theDefinedLibrary = request.op_libraryid>
		<cfinclude template="#APPLICATION.URI.1i00#/1i00_incGetLibraryContextQuery_libDescData.q">
		
		<cfset REQUEST.stLibraryContextData = Duplicate(stLibraryContextData) />
		<cfset request.tableBGColorDark = REQUEST.getLibraryContext.Library_TableBGColourDark><!--- dfdfdf --->
		<cfset request.tableBGColorLight = REQUEST.getLibraryContext.Library_TableBGColourLight><!--- F5F5F5 --->
		<cfset REQUEST.tableBGColorDark = request.tableBGColorDark>
		<cfset REQUEST.tableBGColorLight = request.tableBGColorLight>		
		
		<cfset request.THIS_WorkflowtypeCode = getWFitem.WFS_WorkFlowTypeCode>

		<Cfset use_wfs_WorkFlowTypeCode = getWFitem.WFS_WorkFlowTypeCode>

		<cfset request.op_userid = arguments.jwtData.sessions.userid>

		<cfset request.THIS_currentStageCode = getWFitem.StageCode>
		<cfset wfcurrentStage = getWFitem.StageCode>

		<cfset request.THIS_currentStageIterationNo = 1>
		<Cfset request.THIS_currentStageDescription = getWFitem.Stage_Description>
		<Cfset request.THIS_currentStageSeqNo = getWFitem.Stage_SeqNo>

		<cfparam name="appoint" default="0">
		<cfparam name="managerchange" default="0">
		<cfparam name="specialCommentSuffix" default=""><!--- if want to put special suffix after normal comment --->
		<cfparam name="changeUserOverrideSendEmail" default=""><!--- can be blank, send or dontSend --->


		<!--- LL UI 2022-08-24 adding defaults for the new params as they are checked for contents below but error out if they are undefined --->
		<cfparam name="new_userid" default="">
		<cfparam name="new_usergroupid" default="">
		<cfparam name="new_usergroup_selected_userid" default="">

		<cfset whatAction = "update">
		<Cfset upd_rc = arguments.RoleCode>

		<cfset new_userid = arguments.newUserID>

		
		<cfif len(ru_selecting_provider) gt 0>
			<cfset ru_selecting_provider=trim(ru_selecting_provider)>

			<cfset user_and_provider_id = arguments.newUserID>
			
			<!--- <cfset new_userid=request.op_userid> --->
			<!--- <cfset new_providerID=0> --->
			<cfset new_provider_companyID = 0>
			<cfset new_provider_contactPerson = listFirst(user_and_provider_id)>

			<cfif listLen(user_and_provider_id) gt 1 and isNumeric(listLast(user_and_provider_id))>
				<cfset new_provider_companyID = listLast(user_and_provider_id)>
			</cfif>

			<cfset new_userid = new_provider_contactPerson>			
			
		</cfif>

		<Cfset theWorkflowItemSeqNo = arguments.ItemSeqNo>

		<cfif isDefined("new_userid") and listFirst( new_userid, "_") eq "usergroup">
			<cfset new_usergroupid = listDeleteAt( new_userid, 1, "_")>
			<cfset new_usergroup_selected_userid = arguments.newUsergroupUserID>
			
			<!--- this is just placeholder for database to cater to foreign key requirements --->
			<cfset new_userid =  request.op_userid>
		<cfelse>
			<cfset new_usergroupid = "">
			<cfset new_usergroup_selected_userid = "">
			
		</cfif>
		
		<cfset doChangeUser = isDefined("new_userid") and len(trim(new_userid)) gt 0>
		<cfset doChangeProvider	= isDefined("new_provider_contactPerson") and len(trim(new_provider_contactPerson)) gt 0>	

		<cfif upd_rc neq "">
			<cfquery name="getPreviousUserDetails" datasource="#request.getLibraryContext.LibraryODBCsource#">
				SELECT 		SG_User.name as user_name, UG.UsergroupDescription as usegroup_name, SG_UserInUsergroup.name as userinusergroup_name,
							ToBeAssigned
				FROM 		[1i00_Central]..WFS_Item_role2users_FixedMappings
							LEFT JOIN [1i00_SmarterWare]..sg_users AS SG_User ON SG_User.userid = [1i00_Central]..WFS_Item_role2users_FixedMappings.FixedMapping_UserID
							LEFT JOIN [1i00_Central]..i00use_LibUsergroups UG ON UG.UsergroupID = [1i00_Central]..WFS_Item_role2users_FixedMappings.FixedMapping_UsergroupID
																				AND UG.LibraryID = [1i00_Central]..WFS_Item_role2users_FixedMappings.LibraryID
							LEFT JOIN [1i00_SmarterWare]..sg_users AS SG_UserInUsergroup ON SG_UserInUsergroup.userid = [1i00_Central]..WFS_Item_role2users_FixedMappings.FixedMapping_Usergroup_SelectedUserID
				WHERE		[1i00_Central]..WFS_Item_role2users_FixedMappings.LibraryID=#request.op_libraryid#
				AND			ItemSeqNo=#theWorkflowItemSeqNo#
				AND			WorkFlowTypeCode='#use_wfs_WorkFlowTypeCode#'
				AND			RoleCode=#upd_rc#
			</cfquery>

			<cfif getPreviousUserDetails.userinusergroup_name neq "">
				<cfset previousUserDetails = "#getPreviousUserDetails.userinusergroup_name# in #getPreviousUserDetails.usegroup_name#">
			<cfelseif getPreviousUserDetails.usegroup_name neq "">
				<cfset previousUserDetails = getPreviousUserDetails.usegroup_name>
			<cfelse>
				<cfset previousUserDetails = getPreviousUserDetails.user_name>
			</cfif>

			<cfif getPreviousUserDetails.ToBeAssigned eq "tba">
				<cfset newToBeAssigned = "done">
			<cfelse>
				<cfset newToBeAssigned = getPreviousUserDetails.ToBeAssigned>
			</cfif>

		<cfelse>
			<cfset previousUserDetails = "">
			<cfset newToBeAssigned = "">
		</cfif>


		<cftransaction>
			
			<cfif appoint eq 1>
				<cfquery name="getOldUser" datasource="#request.getLibraryContext.LibraryODBCsource#">
					SELECT		FixedMapping_UserID AS oldUser
					FROM 		[1i00_Central]..WFS_Item_role2users_FixedMappings
					WHERE		LibraryID=#request.op_libraryid#
					AND			ItemSeqNo=#theWorkflowItemSeqNo#
					AND			WorkFlowTypeCode='#use_wfs_WorkFlowTypeCode#'
					AND			RoleCode=#upd_rc#
				</cfquery>
			
				<cfset oldUser=getOldUser.oldUser>
			
			</cfif>

			<cfif doChangeProvider>

				<cfquery name="update_Provider" datasource="#request.getLibraryContext.LibraryODBCsource#">
					UPDATE [1i00_Central]..WFS_Task
					SET

						<!--- LL UI 2022-08-24 changed new_providerID to new_provider_companyID and added new_provider_contactPerson - START --->
						<cfif new_provider_companyID eq 0>
							<cfset new_provider_companyID="NULL">
						</cfif>
						<cfif ru_selecting_provider eq "design">
							WFS_Designer_Company=#new_provider_companyID#,
							WFS_Designer_ContactPerson='#new_provider_contactPerson#'
						<cfelseif ru_selecting_provider eq "printing">
							WFS_Printer_Company=#new_provider_companyID#,
							WFS_Printer_ContactPerson='#new_provider_contactPerson#'
						</cfif>
						<!--- LL UI 2022-08-24 changed new_providerID to new_provider_companyID and added new_provider_contactPerson - END --->

					WHERE
							LibraryID=#request.op_libraryid#
							AND
							ItemSeqNo=#theWorkflowItemSeqNo#
				</cfquery>

			</cfif>

			<cfquery name="delete_FixedMappings" datasource="#request.getLibraryContext.LibraryODBCsource#">
				DELETE FROM [1i00_Central]..WFS_Item_role2users_FixedMappings
				WHERE
						LibraryID=#request.op_libraryid#
						AND
						ItemSeqNo=#theWorkflowItemSeqNo#
						AND
						WorkFlowTypeCode='#use_wfs_WorkFlowTypeCode#'
						AND
						RoleCode=#upd_rc#
			</cfquery>
			<cfif len(trim(new_userid)) gt 0 or ( len(trim(new_usergroupid)) gt 0 and len(trim(new_usergroup_selected_userid)) gt 0 )>

				<cfif ( len(trim(new_usergroupid)) gt 0 and len(trim(new_usergroup_selected_userid)) gt 0 )>
					<cfset add_usergroup_fields = true>
				<cfelse>
					<cfset add_usergroup_fields = false>
				</cfif>
				<cfif len(trim(new_usergroup_selected_userid)) gt 0> 
					<cfset usergroup_selected_userid_to_insert = new_usergroup_selected_userid>
					
					<cfif uCase(new_usergroup_selected_userid) eq "ALL">
						<cfset usergroup_selected_userid_to_insert = "">
					</cfif>
				</cfif>
					


				<cfquery name="qWfsRoles" datasource="#request.getLibraryContext.LibraryODBCsource#">
						INSERT INTO [1i00_Central]..WFS_Item_role2users_FixedMappings
							(
								LibraryID,
								ItemSeqNo,
								WorkFlowTypeCode,
								RoleCode,
								FixedMapping_UserID,
								<cfif add_usergroup_fields>
									FixedMapping_UsergroupID,
									FixedMapping_Usergroup_SelectedUserID,
								</cfif>
								FixedMapping_dt,
								ToBeAssigned
							)
						VALUES
							(
								#request.op_libraryid#,
								#theWorkflowItemSeqNo#,
								'#use_wfs_WorkFlowTypeCode#',
								#upd_rc#,
								'#new_userid#',
								<!--- LL UI 2022-08-17 moved and added to large conditionals to above this cfquery for readability --->
								<cfif add_usergroup_fields>
								'#new_usergroupid#',
								
								'#usergroup_selected_userid_to_insert#',
								</cfif>
								GETDATE(),
								'#newToBeAssigned#'
							)
				</cfquery>


				<cfquery name="getNewUserDetails" datasource="#request.getLibraryContext.LibraryODBCsource#">
					SELECT 		name, first_name, last_name
					FROM 		[1i00_SmarterWare]..sg_users
					WHERE		userid = '#new_userid#'
				</cfquery>


			<cfelse>

				<!--- if user is blank (ie. making role inactve) must delete from RoleSectionsTrack table as well --->

				<!--- if role has answered questions, then can't delete role - show message about this --->
				<cfquery name="qAnsweredQuestions" datasource="#request.getLibraryContext.LibraryODBCsource#">
					SELECT		ResponsibilityCode
					FROM 		[1i00_Central]..WFS_Item_ResponsibilityValues
					WHERE		LibraryID=#request.op_libraryid#
					AND			ItemSeqNo=#theWorkflowItemSeqNo#
					AND			WorkFlowTypeCode='#use_wfs_WorkFlowTypeCode#'
					AND			RoleCode=#upd_rc#
				</cfquery>

				<cfif qAnsweredQuestions.recordCount eq 0>
					<cfquery name="delete_RoleSections_Track" datasource="#request.getLibraryContext.LibraryODBCsource#">
						DELETE FROM [1i00_Central]..WFS_Item_Stage_Iteration_RoleSections_Track
						WHERE		LibraryID=#request.op_libraryid#
						AND			ItemSeqNo=#theWorkflowItemSeqNo#
						AND			WorkFlowTypeCode='#use_wfs_WorkFlowTypeCode#'
						AND			RoleCode=#upd_rc#
					</cfquery>
				<cfelse>

					<cfoutput>
					<script>
						alert("Can't delete role - already answered questions.");
						window.location.href = "#APPLICATION.URI.1i00#/1i00_Rworkflow.cfm?theWorkflowItemSeqNo=#theWorkflowItemSeqNo#&do=allparticipants";
					</script>
					</cfoutput>
					<cfabort>

				</cfif>


			</cfif>


			<!--- O.K. 2003-12-15 O.K. - request by Andrew Sleath--->
			<cfif managerchange gt 0>

				<cfquery name="getNewUserDetails" datasource="#request.getLibraryContext.LibraryODBCsource#">
					SELECT
							SG.name, first_name, last_name,
							SG.email,
							SG.phone,
							SG.userid
					FROM
							[1i00_SmarterWare]..sg_users SG
					WHERE
							SG.UserID='#new_userid#'
				</cfquery>


				<cfquery name="updateWFmanager" datasource="#request.getLibraryContext.LibraryODBCsource#">
					UPDATE
							[1i00_Central]..i00wf_Item
							SET
							Item_SubmittedBy='#new_userid#'
					WHERE
							LibraryID=#request.op_libraryid#
							AND
							ItemSeqNo=#theWorkflowItemSeqNo#
				</cfquery>

				<cfif IsDefined("new_usergroupid") and len(trim(new_usergroupid)) gt 0>

					<cfquery name="getUGName" datasource="#request.getLibraryContext.LibraryODBCsource#">
						SELECT 		UsergroupDescription
						FROM		[1i00_Central]..i00use_LibUsergroups
						WHERE		LibraryID=#request.op_LibraryID#
						AND				UsergroupID = '#new_usergroupid#'
					</cfquery>

					<cfset specialAutomaticComment="#getUGName.UsergroupDescription# assigned to Manager">

				<cfelse>
					<cfset specialAutomaticComment="#getNewUserDetails.first_name# #getNewUserDetails.last_name# assigned to Manager">
				</cfif>

				<!--- if want to put special suffix after normal comment --->
				<cfif specialCommentSuffix neq "">
					<cfset specialAutomaticComment = specialAutomaticComment & " #specialCommentSuffix#">
				</cfif>

				<!--- <cfset specialAutomaticComment="#getNewUserDetails.name# assigned to Manager"> --->
				<cfset formattedSpecialComment = request.formatForDBInsert(specialAutomaticComment)>


				<cfif IsDefined("getUserProfile.first_name")>

					<cfquery
						name="specialSaveComment" datasource="#request.getLibraryContext.LibraryODBCsource#">
						INSERT INTO	[1i00_Central]..WFS_Task_Observers_Comments
							(
								StageCode_when_saved,
								IterationNo,
								LibraryID,
								ItemSeqNo,
								dt_posted,
								by_userid,
								text,
								username,
								useremail,
								userphone,
								ReferenceComment
							)
						VALUES
							(
								#wfcurrentStage#,
								#request.THIS_currentStageIterationNo#,
								#request.op_libraryid#,
								#theWorkflowItemSeqNo#,
								GETDATE(),
								'#request.op_userid#',
								'#formattedSpecialComment#',
								'#request.getUserProfile.first_Name# #request.getUserProfile.last_Name#',
								'#request.getUserProfile.email#',
								'#request.getUserProfile.phone#',
								1
							)
					</cfquery>

				</cfif>

			</cfif>


		</cftransaction>


		<cfif appoint eq 1>
			<cfmodule template="#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
					ItemID="#theWorkflowItemSeqNo#"
					observerUserID="#oldUser#"
					call="addObserver"
				>
		</cfif>

		<cfif new_userid eq "">
			<cfset logNewUser = "">

		<cfelseif IsDefined("new_usergroupid") and new_usergroupid neq "">
			<cfquery name="getUserGroupDesc" datasource="#request.dsns.onei00maindb#">
				SELECT		UsergroupDescription
				FROM		i00use_LibUsergroups
				WHERE	UsergroupID = '#new_usergroupid#'
				AND			LibraryID=#request.op_libraryid#
			</cfquery>

			<!--- LL UI 2022-08-24 added this from 1i00_wfs_page_CHANGEUSER_ugSelUser.cfm --->
			<cfquery name="getNewUserDetails" datasource="#request.getLibraryContext.LibraryODBCsource#">
				SELECT 		UG.UsergroupDescription, SG.name
				FROM 		[1i00_Central]..WFS_Item_role2users_FixedMappings
									LEFT JOIN [1i00_Central]..i00use_LibUsergroups UG ON UG.UsergroupID = [1i00_Central]..WFS_Item_role2users_FixedMappings.FixedMapping_UsergroupID
																						AND UG.LibraryID = [1i00_Central]..WFS_Item_role2users_FixedMappings.LibraryID
									LEFT JOIN [1i00_SmarterWare]..sg_users AS SG ON SG.userid = [1i00_Central]..WFS_Item_role2users_FixedMappings.FixedMapping_Usergroup_SelectedUserID
				WHERE		[1i00_Central]..WFS_Item_role2users_FixedMappings.LibraryID=#request.op_libraryid#
				AND				ItemSeqNo=#theWorkflowItemSeqNo#
				AND				WorkFlowTypeCode='#use_wfs_WorkFlowTypeCode#'
				AND				RoleCode=#upd_rc#
				
			</cfquery>
			<cfif getNewUserDetails.name neq "">
				<cfset logNewUser = "#getNewUserDetails.name# in #getNewUserDetails.UsergroupDescription#">
			<cfelse>
				<cfset logNewUser = "All Users in #getNewUserDetails.UsergroupDescription#">
			</cfif>

		<cfelse>
			<cfset logNewUser = "#getNewUserDetails.first_name# #getNewUserDetails.last_name#">
		</cfif>

		<cfif previousUserDetails neq logNewUser>
			<cfmodule template="#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
					call="logChangeRoleIntoComments"
					ItemID="#theWorkflowItemSeqNo#"
					RoleCode="#upd_rc#"
					previousUser="#previousUserDetails#"
					newUser="#logNewUser#"
					specialCommentSuffix="#specialCommentSuffix#"
			>
			<cfif changeUserOverrideSendEmail neq "dontSend">

				<!--- BH 29/5/2015 - some roles (eg. Fin Appr) have special email so don't send normal role change email --->
				<cfquery name="qDisableChangeRoleEmail" datasource="#request.getLibraryContext.LibraryODBCsource#">
					SELECT 		StageRole_DisableChangeRoleEmail
					FROM 		[1i00_Central]..WFS_WorkflowType_Stage_Role_m2m
					WHERE		RoleCode = <cfqueryparam value="#upd_rc#" cfsqltype="CF_SQL_INTEGER">
				</cfquery>

				<cfif qDisableChangeRoleEmail.StageRole_DisableChangeRoleEmail eq 0>
					<cfmodule template="#APPLICATION.URI.1i00#/1i00_WFS_API.cfm"
						ItemID="#theWorkflowItemSeqNo#"
						pRole="#upd_rc#"
						call="doChangeRoleEmail"
						var="theResult"
					>
				</cfif>

			</cfif>
		</cfif>

		<cfset APPLICATION.oWorkflowToDo.syncToDoRoles( ItemSeqNo = theWorkflowItemSeqNo )>		

		<cfset updatedRoles = getWorkFlowAllRoles( theWorkflowItemSeqNo, jwtData )>

		<cfreturn updatedRoles>

	</cffunction>


</cfcomponent>